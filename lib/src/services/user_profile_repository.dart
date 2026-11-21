import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import '../models/user_profile.dart';

class StorageUploadException implements Exception {
  StorageUploadException(this.cause);

  final Object cause;

  @override
  String toString() => cause.toString();
}

abstract interface class UserProfileRepository {
  Future<UserProfile?> getProfile(String uid);

  Stream<UserProfile?> watchProfile(String uid);

  Future<void> updateVisibility({required String uid, required bool isVisible});

  Future<void> saveProfile({
    required UserProfile profile,
    PlatformFile? cvFile,
  });
}

class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final reference = _firestore.collection('users').doc(uid);
    late final DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await reference.get(
        const GetOptions(source: Source.serverAndCache),
      );
    } on FirebaseException catch (error, stackTrace) {
      if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
        rethrow;
      }

      try {
        snapshot = await reference.get(
          const GetOptions(source: Source.cache),
        );
      } on FirebaseException {
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (!snapshot.exists) Error.throwWithStackTrace(error, stackTrace);
    }
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserProfile.fromMap(data);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromMap(data);
    });
  }

  @override
  Future<void> updateVisibility({
    required String uid,
    required bool isVisible,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'isVisible': isVisible,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveProfile({
    required UserProfile profile,
    PlatformFile? cvFile,
  }) async {
    final profileReference = _firestore.collection('users').doc(profile.uid);
    await profileReference.set(profile.toMap(), SetOptions(merge: true));
    if (cvFile == null) return;

    try {
      await _auth.currentUser?.getIdToken(true);
      final bytes = await cvFile.readAsBytes();
      final reference = _storage.ref().child(
        'users/${profile.uid}/cv/${DateTime.now().millisecondsSinceEpoch}_${cvFile.name}',
      );
      final task = await reference.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeFor(cvFile)),
      );
      await profileReference.set({
        'cvUrl': await task.ref.getDownloadURL(),
        'cvFileName': cvFile.name,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (error) {
      throw StorageUploadException(error);
    }
  }

  String _contentTypeFor(PlatformFile file) {
    final extension =
        (file.extension ?? file.name.split('.').last).toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => 'application/pdf',
    };
  }
}
