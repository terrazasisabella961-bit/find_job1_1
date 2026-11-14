import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/company.dart';
import '../models/job_posting.dart';

abstract interface class RecruitmentRepository {
  Stream<Company?> watchCompany(String ownerUid);

  Future<void> saveCompany(Company company);

  Stream<List<JobPosting>> watchPublicJobs();

  Stream<List<JobPosting>> watchCompanyJobs(String ownerUid);

  Future<String> saveJob(JobPosting job);

  Future<void> updateJobStatus(String jobId, String status);
}

class FirebaseRecruitmentRepository implements RecruitmentRepository {
  FirebaseRecruitmentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
          (snapshot) => snapshot.docs
              .map((document) => JobPosting.fromMap(document.id, document.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
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
    final reference = job.id.isEmpty ? jobs.doc() : jobs.doc(job.id);
    final companyReference = _firestore
        .collection('companies')
        .doc(job.companyId);

    await _firestore.runTransaction((transaction) async {
      final companySnapshot = await transaction.get(companyReference);
      final companyData = companySnapshot.data();
      if (!companySnapshot.exists ||
          companyData == null ||
          companyData['ownerUid'] != job.ownerUid) {
        throw StateError('No tienes permiso para administrar esta empresa.');
      }
      final existing = await transaction.get(reference);
      if (existing.exists && existing.data()?['ownerUid'] != job.ownerUid) {
        throw StateError('No tienes permiso para modificar esta oferta.');
      }
      transaction.set(reference, {
        ...job.toMap(),
        'createdAt':
            existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return reference.id;
  }

  @override
  Future<void> updateJobStatus(String jobId, String status) {
    return _firestore.collection('jobs').doc(jobId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
