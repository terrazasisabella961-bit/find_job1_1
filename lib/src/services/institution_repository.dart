import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/file_upload_mode.dart';
import '../data/demo_catalog.dart';
import '../models/institution.dart';
import '../models/institution_course.dart';

abstract interface class InstitutionRepository {
  Stream<Institution?> watchInstitution(String uid);

  Future<void> saveInstitutionRequest(Institution institution);

  Stream<List<InstitutionCourse>> watchInstitutionCourses(String uid);

  Stream<List<InstitutionCourse>> watchPublishedCourses();

  Future<String> saveCourse(InstitutionCourse course);

  Future<void> retireCourse({
    required String courseId,
    required String ownerUid,
  });

  Future<void> publishCourse({
    required String courseId,
    required String ownerUid,
  });
}

class FirebaseInstitutionRepository implements InstitutionRepository {
  FirebaseInstitutionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<Institution?> watchInstitution(String uid) {
    return _firestore.collection('institutions').doc(uid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Institution.fromMap(snapshot.id, data);
    });
  }

  @override
  Future<void> saveInstitutionRequest(Institution institution) async {
    final reference = _firestore
        .collection('institutions')
        .doc(institution.uid);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      final data = existing.data();
      if (existing.exists && data?['ownerUid'] != institution.uid) {
        throw StateError('No tienes permiso para modificar esta institución.');
      }
      transaction.set(reference, {
        ...institution.toMap(),
        'verificationStatus': simulateInstitutionVerification
            ? 'verified'
            : (data?['verificationStatus'] ??
                institution.verificationStatus),
        'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<List<InstitutionCourse>> watchInstitutionCourses(String uid) {
    return _firestore
        .collection('courses')
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (document) =>
                        InstitutionCourse.fromMap(document.id, document.data()),
                  )
                  .toList()
                ..sort((a, b) {
                  final aDate = a.createdAt ?? DateTime(1970);
                  final bDate = b.createdAt ?? DateTime(1970);
                  return bDate.compareTo(aDate);
                }),
        );
  }

  @override
  Stream<List<InstitutionCourse>> watchPublishedCourses() {
    return _firestore
        .collection('courses')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map(
          (snapshot) => withDemoCourses(
            snapshot.docs
                .map(
                  (document) =>
                      InstitutionCourse.fromMap(document.id, document.data()),
                )
                .toList(),
          ),
        );
  }

  @override
  Future<String> saveCourse(InstitutionCourse course) async {
    final reference = course.id.isEmpty
        ? _firestore.collection('courses').doc()
        : _firestore.collection('courses').doc(course.id);
    await _firestore.runTransaction((transaction) async {
      final institutionReference = _firestore
          .collection('institutions')
          .doc(course.ownerUid);
      final institution = await transaction.get(institutionReference);
      if (!institution.exists ||
          institution.data()?['ownerUid'] != course.ownerUid) {
        throw StateError('No se encontró la institución de esta cuenta.');
      }
      transaction.set(reference, {
        ...course.toMap(),
        'createdAt': course.createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(course.createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return reference.id;
  }

  @override
  Future<void> retireCourse({
    required String courseId,
    required String ownerUid,
  }) async {
    final reference = _firestore.collection('courses').doc(courseId);
    await _firestore.runTransaction((transaction) async {
      final course = await transaction.get(reference);
      if (!course.exists || course.data()?['ownerUid'] != ownerUid) {
        throw StateError('No tienes permiso para retirar este curso.');
      }
      final institution = await transaction.get(
        _firestore.collection('institutions').doc(ownerUid),
      );
      if (!institution.exists || institution.data()?['ownerUid'] != ownerUid) {
        throw StateError('No se encontró la institución de esta cuenta.');
      }
      transaction.update(reference, {
        'status': 'retired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> publishCourse({
    required String courseId,
    required String ownerUid,
  }) async {
    final reference = _firestore.collection('courses').doc(courseId);
    await _firestore.runTransaction((transaction) async {
      final course = await transaction.get(reference);
      if (!course.exists || course.data()?['ownerUid'] != ownerUid) {
        throw StateError('No tienes permiso para publicar este curso.');
      }
      final institution = await transaction.get(
        _firestore.collection('institutions').doc(ownerUid),
      );
      if (!institution.exists || institution.data()?['ownerUid'] != ownerUid) {
        throw StateError('No se encontró la institución de esta cuenta.');
      }
      transaction.update(reference, {
        'status': 'published',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
