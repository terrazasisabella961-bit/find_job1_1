import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/demo_catalog.dart';
import '../models/company.dart';
import '../models/job_posting.dart';

abstract interface class RecruitmentRepository {
  Stream<Company?> watchCompany(String ownerUid);

  Future<void> saveCompany(Company company);

  Stream<List<JobPosting>> watchPublicJobs();

  Stream<List<Company>> watchLocatedCompanies();

  Stream<List<JobPosting>> watchCompanyJobs(String ownerUid);

  Future<String> saveJob(JobPosting job);

  Future<void> updateJobStatus(String jobId, String status);
}

class FirebaseRecruitmentRepository implements RecruitmentRepository {
  FirebaseRecruitmentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const _jobSaveTimeout = Duration(seconds: 30);

  @override
  Stream<Company?> watchCompany(String ownerUid) {
    return _firestore.collection('companies').doc(ownerUid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Company.fromMap(snapshot.id, data);
    });
  }

  @override
  Future<void> saveCompany(Company company) async {
    if (company.ownerUid.trim().isEmpty || company.id != company.ownerUid) {
      throw ArgumentError('El UID de la empresa no es válido.');
    }
    if (company.name.trim().isEmpty || company.sector.trim().isEmpty) {
      throw ArgumentError('El nombre y el sector de la empresa son obligatorios.');
    }

    final reference = _firestore.collection('companies').doc(company.ownerUid);
    try {
      await _firestore.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(reference);
          transaction.set(reference, {
            ...company.toMap(),
            'createdAt':
                snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to save company ${company.ownerUid}',
        name: 'FirebaseRecruitmentRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<JobPosting>> watchPublicJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map(
          (snapshot) => withDemoJobs(
            snapshot.docs
                .map(
                  (document) =>
                      JobPosting.fromMap(document.id, document.data()),
                )
                .toList(),
          ),
        );
  }

  @override
  Stream<List<Company>> watchLocatedCompanies() {
    return _firestore
        .collection('companies')
        .snapshots()
        .map(
          (snapshot) => withDemoCompanies(
            snapshot.docs
                .map((document) => Company.fromMap(document.id, document.data()))
                .where((company) => company.hasCoordinates)
                .toList(),
          ),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stack, EventSink<List<Company>> sink) {
              sink.add(withDemoCompanies(const []));
            },
          ),
        );
  }

  @override
  Stream<List<JobPosting>> watchCompanyJobs(String ownerUid) {
    return _firestore
        .collection('jobs')
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => JobPosting.fromMap(document.id, document.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  @override
  Future<String> saveJob(JobPosting job) async {
    final jobs = _firestore.collection('jobs');
    final documentId = job.id.isEmpty ? jobs.doc().id : job.id;
    final reference = jobs.doc(documentId);
    var stage = 'authentication';

    Future<String> writeAndVerify() async {
      try {
        developer.log(
          'Starting job save ($documentId, ${job.status})',
          name: 'FirebaseRecruitmentRepository',
        );
        final user = _auth.currentUser;
        if (user == null) {
          throw StateError('Debes iniciar sesión para publicar un empleo.');
        }
        if (user.uid != job.ownerUid || job.companyId != user.uid) {
          throw StateError(
            'La sesión actual no corresponde a la empresa de esta oferta.',
          );
        }
        if (job.title.trim().isEmpty || job.description.trim().isEmpty) {
          throw ArgumentError('El título y la descripción son obligatorios.');
        }

        stage = 'write';
        await reference
            .set({
              ...job.toMap(),
              'createdAt': job.id.isEmpty
                  ? FieldValue.serverTimestamp()
                  : Timestamp.fromDate(job.createdAt),
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(_jobSaveTimeout);

        stage = 'verification';
        final saved = await reference
            .get(const GetOptions(source: Source.server))
            .timeout(_jobSaveTimeout);
        final savedData = saved.data();
        if (!saved.exists ||
            savedData == null ||
            savedData['ownerUid'] != user.uid ||
            savedData['companyId'] != job.companyId ||
            savedData['status'] != job.status ||
            savedData['title'] != job.title.trim()) {
          throw StateError(
            'Firestore no confirmó los datos de la oferta guardada.',
          );
        }
        developer.log(
          'Job save confirmed ($documentId)',
          name: 'FirebaseRecruitmentRepository',
        );
        return documentId;
      } on Object catch (error, stackTrace) {
        developer.log(
          'Job save failed at $stage ($documentId)',
          name: 'FirebaseRecruitmentRepository',
          error: error,
          stackTrace: stackTrace,
        );
        if (stage == 'verification' ||
            error is TimeoutException ||
            error is FirebaseException &&
                const {
                  'unavailable',
                  'deadline-exceeded',
                  'network-request-failed',
                }.contains(error.code)) {
          throw JobSaveOutcomeUnknownException(documentId, stage);
        }
        rethrow;
      }
    }

    try {
      return await writeAndVerify().timeout(_jobSaveTimeout);
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Job save timed out at $stage ($documentId); write outcome may be unknown',
        name: 'FirebaseRecruitmentRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw JobSaveOutcomeUnknownException(documentId, stage);
    }
  }

  @override
  Future<void> updateJobStatus(String jobId, String status) {
    return _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class JobSaveOutcomeUnknownException implements Exception {
  const JobSaveOutcomeUnknownException(this.jobId, this.stage);

  final String jobId;
  final String stage;
}
