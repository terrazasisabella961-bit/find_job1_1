import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/services/auth_error_message.dart';

void main() {
  test('maps web permission-denied wrappers to a Spanish save error', () {
    const wrapped =
        'RethrownDartError: Error: Dart exception: '
        '[cloud_firestore/permission-denied] Missing or insufficient permissions.';
    expect(
      authErrorMessage(wrapped),
      contains('Firebase rechazó guardar los datos'),
    );
  });
}
