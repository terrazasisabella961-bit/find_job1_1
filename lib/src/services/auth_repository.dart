import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  });

  Future<UserCredential> register({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  });

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle() {
    return _auth.signInWithProvider(GoogleAuthProvider());
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    final currentEmail = user?.email;
    if (user == null || currentEmail == null) {
      throw StateError('No hay una sesión de correo electrónico activa.');
    }
    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
