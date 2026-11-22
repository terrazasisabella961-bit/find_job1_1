import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_repository.dart';
import '../services/institution_repository.dart';
import '../services/job_application_repository.dart';
import '../services/recruitment_repository.dart';
import '../services/user_profile_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_feedback.dart';
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
    this.applicationRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final int initialSelectedIndex;
  final String accountType;
  final RecruitmentRepository? recruitmentRepository;
  final InstitutionRepository? institutionRepository;
  final JobApplicationRepository? applicationRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex = widget.initialSelectedIndex;
  late final RecruitmentRepository _recruitmentRepository =
      widget.recruitmentRepository ?? FirebaseRecruitmentRepository();
  late final InstitutionRepository _institutionRepository =
      widget.institutionRepository ?? FirebaseInstitutionRepository();
  late final JobApplicationRepository _applicationRepository =
      widget.applicationRepository ?? FirebaseJobApplicationRepository();

  List<AppNavDestination> get _navItems {
    return switch (widget.accountType) {
      'company' => AppBottomNavigation.companyItems,
      'institution' => AppBottomNavigation.institutionItems,
      _ => AppBottomNavigation.studentItems,
    };
  }

  void _openLabeledTab(String label) {
    final index = _navItems.indexWhere((item) => item.label == label);
    if (index >= 0) setState(() => _selectedIndex = index);
  }

  Widget _employmentTab({required User? user}) {
    if (user == null) {
      return EmploymentScreen(
        repository: _recruitmentRepository,
        onOpenCatalog: () => _openLabeledTab('Cursos'),
      );
    }
    return StreamBuilder<UserProfile?>(
      stream: widget.profileRepository.watchProfile(user.uid),
      builder: (context, snapshot) {
        return EmploymentScreen(
          repository: _recruitmentRepository,
          onOpenCatalog: () => _openLabeledTab('Cursos'),
          profile: snapshot.data,
          showSuggestions: true,
          suggestionsLoading:
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData,
          onCompleteProfile: () => _openLabeledTab('Cuenta'),
          applicationRepository: _applicationRepository,
        );
      },
    );
  }

  List<Widget> _pages({required User? user}) {
    final accountType = widget.accountType;
    final courses = CourseCatalogScreen(
      onOpenAccount: () => _openLabeledTab('Cuenta'),
      courseRepository: _institutionRepository,
    );
    if (accountType == 'company' && user != null) {
      return [
        RecruitmentScreen(
          ownerUid: user.uid,
          repository: _recruitmentRepository,
          applicationRepository: _applicationRepository,
          authRepository: widget.authRepository,
        ),
        RecruitmentScreen(
          ownerUid: user.uid,
          repository: _recruitmentRepository,
          applicationRepository: _applicationRepository,
          authRepository: widget.authRepository,
          accountTab: true,
        ),
      ];
    }
    if (accountType == 'institution') {
      return [
        InstitutionPortalScreen(
          authRepository: widget.authRepository,
          repository: _institutionRepository,
        ),
        courses,
        InstitutionPortalScreen(
          authRepository: widget.authRepository,
          repository: _institutionRepository,
          accountTab: true,
        ),
      ];
    }
    return [
      _employmentTab(user: user),
      courses,
      AccountScreen(
        authRepository: widget.authRepository,
        profileRepository: widget.profileRepository,
        onBack: () => _openLabeledTab('Empleo'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authRepository.currentUser;
    final navItems = _navItems;
    final pages = _pages(user: user);
    final selectedIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AppBottomNavigation(
          selectedIndex: selectedIndex,
          items: navItems,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
