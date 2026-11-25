import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_repository.dart';
import '../services/user_profile_repository.dart';
import 'app_bottom_navigation.dart';

class StudentAgeGate extends StatelessWidget {
  const StudentAgeGate({
    required this.userUid,
    required this.authRepository,
    required this.profileRepository,
    required this.child,
    super.key,
  });

  final String userUid;
  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: profileRepository.watchProfile(userUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile != null && profile.isUnder18) {
          return _UnderageBlockedScreen(
            onLeave: authRepository.signOut,
          );
        }
        return child;
      },
    );
  }
}

class _UnderageBlockedScreen extends StatelessWidget {
  const _UnderageBlockedScreen({required this.onLeave});

  final Future<void> Function() onLeave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cake_outlined, color: appOrangeColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'Solo para mayores de 18 años',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: appTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'CochaConecta es para postulantes mayores de edad. '
                'Esta cuenta no puede iniciar sesión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: appMutedColor, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onLeave,
                style: FilledButton.styleFrom(
                  backgroundColor: appOrangeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
