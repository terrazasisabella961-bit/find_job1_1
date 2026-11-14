import 'package:flutter/material.dart';

import '../services/auth_repository.dart';
import '../services/institution_repository.dart';
import '../services/recruitment_repository.dart';
import '../services/user_profile_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import 'account_screen.dart';
import 'course_catalog_screen.dart';
import 'employment_screen.dart';
import 'institution_portal_screen.dart';
import 'recruitment_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.authRepository,
    required this.profileRepository,
    this.initialSelectedIndex = 0,
    this.accountType = 'student',
    this.recruitmentRepository,
    this.institutionRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final int initialSelectedIndex;
  final String accountType;
  final RecruitmentRepository? recruitmentRepository;
  final InstitutionRepository? institutionRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex = widget.initialSelectedIndex;
  late final RecruitmentRepository _recruitmentRepository =
      widget.recruitmentRepository ?? FirebaseRecruitmentRepository();
  late final InstitutionRepository _institutionRepository =
      widget.institutionRepository ?? FirebaseInstitutionRepository();

  void _openCatalog() {
    setState(() => _selectedIndex = 4);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authRepository.currentUser;
    final accountType = widget.accountType;
    final pages = <Widget>[
      EmploymentScreen(
        repository: _recruitmentRepository,
        onOpenCatalog: _openCatalog,
      ),
      accountType == 'company' && user != null
          ? RecruitmentScreen(
              ownerUid: user.uid,
              repository: _recruitmentRepository,
            )
          : _AccountTypeNotice(
              title: 'Acceso para empresas',
              message: 'Usa una cuenta corporativa independiente para administrar ofertas.',
              onSignOut: widget.authRepository.signOut,
            ),
      accountType == 'institution'
          ? InstitutionPortalScreen(
              authRepository: widget.authRepository,
              repository: _institutionRepository,
              onInstitutionReady: () {
                if (_selectedIndex != 2 && mounted) {
                  setState(() => _selectedIndex = 2);
                }
              },
            )
          : _AccountTypeNotice(
              title: 'Acceso institucional',
              message: 'Usa una cuenta institucional independiente para administrar cursos.',
              onSignOut: widget.authRepository.signOut,
            ),
      if (accountType == 'company' && user != null)
        RecruitmentScreen(
          ownerUid: user.uid,
          repository: _recruitmentRepository,
        )
      else if (accountType == 'student')
        AccountScreen(
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
          onBack: () => setState(() => _selectedIndex = 0),
        )
      else
        _AccountTypeNotice(
          title: accountType == 'company'
              ? 'Cuenta de empresa'
              : 'Mi institución',
          message: accountType == 'company'
              ? 'Administra tu perfil y tus vacantes desde Reclutar.'
              : 'Administra el perfil institucional y los cursos en Instituciones.',
          onSignOut: widget.authRepository.signOut,
        ),
      CourseCatalogScreen(
        onOpenAccount: () => setState(() => _selectedIndex = 3),
        courseRepository: _institutionRepository,
      ),
      const _ComingSoonScreen(title: 'Extras'),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AppBottomNavigation(
          selectedIndex: _selectedIndex,
          onSelected: (index) {
            if (accountType == 'company' && index == 2) {
              _showAccountNotice('Esta cuenta pertenece a una empresa.');
              return;
            }
            if (accountType == 'institution' && index == 1) {
              _showAccountNotice('Esta cuenta pertenece a una institución.');
              return;
            }
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }

  void _showAccountNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountTypeNotice extends StatelessWidget {
  const _AccountTypeNotice({
    required this.title,
    required this.message,
    required this.onSignOut,
  });

  final String title;
  final String message;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_outlined, color: appOrangeColor, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: appMutedColor, fontSize: 12),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () async {
              try {
                await onSignOut();
              } on Exception catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo cerrar sesión: $error')),
                  );
                }
              }
            },
            child: const Text('Cambiar de cuenta'),
          ),
        ],
      ),
    ),
  );
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, color: appPurpleColor, size: 36),
            const SizedBox(height: 16),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta sección se desarrollará en una etapa posterior.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appMutedColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
