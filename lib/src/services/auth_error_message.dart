import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseException && error is! FirebaseAuthException) {
    return switch (error.code) {
      'permission-denied' || 'storage/unauthorized' =>
        'Firebase rechazó la operación. Revisa las reglas de acceso.',
      'storage/unknown' || 'unavailable' =>
        'El servicio de Firebase no está disponible. Inténtalo más tarde.',
      _ => 'Firebase no pudo completar la solicitud (${error.code}).',
    };
  }
  if (error is! FirebaseAuthException) {
    return 'No se pudo completar la solicitud. Inténtalo nuevamente.';
  }

  return switch (error.code) {
    'invalid-email' => 'El formato del correo electrónico no es válido.',
    'user-disabled' => 'Esta cuenta está deshabilitada.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'El correo electrónico o la contraseña son incorrectos.',
    'email-already-in-use' => 'Ya existe una cuenta con este correo.',
    'weak-password' => 'La contraseña debe tener al menos 8 caracteres.',
    'too-many-requests' =>
      'Hubo demasiados intentos. Espera un momento e inténtalo otra vez.',
    'operation-not-allowed' =>
      'Este método de acceso no está habilitado en Firebase.',
    'account-exists-with-different-credential' =>
      'Ya existe una cuenta con ese correo usando otro método de acceso.',
    'popup-closed-by-user' => 'Se canceló el acceso con Google.',
    'network-request-failed' =>
      'No se pudo conectar. Comprueba tu conexión a internet.',
    'provider-already-linked' =>
      'Este proveedor ya está vinculado con la cuenta.',
    _ => 'Firebase no pudo completar la solicitud (${error.code}).',
  };
}
