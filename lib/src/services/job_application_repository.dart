import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/job_application.dart';

abstract interface class JobApplicationRepository {
  Future<void> submitApplication(JobApplication application);

  Stream<List<JobApplication>> watchCompanyApplications(String companyId);

  Stream<bool> watchHasApplied({
    required String jobId,
    required String applicantUid,
  });
}

class InMemoryJobApplicationRepository implements JobApplicationRepository {
  InMemoryJobApplicationRepository([List<JobApplication>? seed])
    : applications = [...?seed];

  final List<JobApplication> applications;
  final _changes = StreamController<void>.broadcast();

  bool _hasApplied({required String jobId, required String applicantUid}) {
    return applications.any(
      (item) => item.jobId == jobId && item.applicantUid == applicantUid,
    );
  }

  @override
  Future<void> submitApplication(JobApplication application) async {
    applications
      ..removeWhere((item) => item.id == application.id)
      ..add(application);
    _changes.add(null);
  }

  @override
  Stream<List<JobApplication>> watchCompanyApplications(String companyId) {
    return Stream.value(
      applications.where((item) => item.companyId == companyId).toList(),
    );
  }

  @override
  Stream<bool> watchHasApplied({
    required String jobId,
    required String applicantUid,
  }) async* {
    yield _hasApplied(jobId: jobId, applicantUid: applicantUid);
    await for (final _ in _changes.stream) {
      yield _hasApplied(jobId: jobId, applicantUid: applicantUid);
    }
  }
}

class FirebaseJobApplicationRepository implements JobApplicationRepository {
  FirebaseJobApplicationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<void> submitApplication(JobApplication application) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Inicia sesión como postulante para enviar tu ficha.');
    }
    if (user.uid != application.applicantUid) {
      throw StateError('La postulación debe enviarse con tu propia cuenta.');
    }
    final reference = _firestore
        .collection('applications')
        .doc('${application.jobId}_${application.applicantUid}');
    try {
      await reference.set({
        ...application.toMap(),
        'applicantUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == 'already-exists' || error.code == 'permission-denied') {
        throw StateError(
          'No se pudo enviar la ficha. Si ya postulaste, la empresa ya la tiene.',
        );
      }
      rethrow;
    }
  }

  @override
  Stream<List<JobApplication>> watchCompanyApplications(String companyId) {
    return _firestore
        .collection('applications')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
          final applications = snapshot.docs
              .map((doc) => JobApplication.fromMap(doc.id, doc.data()))
              .toList();
          applications.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return applications;
        });
  }

  @override
  Stream<bool> watchHasApplied({
    required String jobId,
    required String applicantUid,
  }) {
    final user = _auth.currentUser;
    if (user == null || user.uid != applicantUid) {
      return Stream.value(false);
    }
    return _firestore
        .collection('applications')
        .where('applicantUid', isEqualTo: applicantUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.any((doc) {
            final data = doc.data();
            return data['jobId'] == jobId ||
                doc.id == '${jobId}_$applicantUid';
          }),
        );
  }
}
