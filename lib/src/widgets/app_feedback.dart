import 'package:flutter/material.dart';

enum AppMessageKind { success, error, info }

const _successColor = Color(0xFF1F7A4D);
const _errorColor = Color(0xFFB3261E);
const _infoColor = Color(0xFF3D2E6B);

/// Muestra un aviso legible sobre el tema oscuro, en el messenger raíz
/// para que no desaparezca al cerrar un formulario.
void showAppMessage(
  BuildContext context,
  String message, {
  AppMessageKind kind = AppMessageKind.info,
}) {
  if (!context.mounted || message.trim().isEmpty) return;
  final messenger =
      context.findRootAncestorStateOfType<ScaffoldMessengerState>() ??
      ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final background = switch (kind) {
    AppMessageKind.success => _successColor,
    AppMessageKind.error => _errorColor,
    AppMessageKind.info => _infoColor,
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 5),
      ),
    );
}

bool ensureFormValid(BuildContext context, GlobalKey<FormState> formKey) {
  final valid = formKey.currentState?.validate() ?? false;
  if (!valid) {
    showAppMessage(
      context,
      'Revisa los campos obligatorios. Los errores aparecen en rojo bajo cada campo.',
      kind: AppMessageKind.error,
    );
  }
  return valid;
}
