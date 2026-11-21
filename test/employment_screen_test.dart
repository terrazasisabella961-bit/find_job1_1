import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/models/company.dart';
import 'package:find_job1_1/src/models/institution.dart';
import 'package:find_job1_1/src/models/institution_course.dart';
import 'package:find_job1_1/src/models/job_posting.dart';
import 'package:find_job1_1/src/models/user_profile.dart';
import 'package:find_job1_1/src/screens/app_shell.dart';
import 'package:find_job1_1/src/screens/employment_screen.dart';
import 'package:find_job1_1/src/services/auth_repository.dart';
import 'package:find_job1_1/src/services/institution_repository.dart';
import 'package:find_job1_1/src/services/recruitment_repository.dart';
import 'package:find_job1_1/src/services/user_profile_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  testWidgets('employment screen shows a useful empty state without samples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmploymentScreen(
            repository: _FakeRecruitmentRepository(const []),
            onOpenCatalog: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay ofertas activas por ahora'), findsOneWidget);
    expect(find.text('215 anuncios encontrados'), findsNothing);
  });

  testWidgets('employment search narrows streamed jobs by keyword', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmploymentScreen(
            repository: _FakeRecruitmentRepository(_sampleJobs),
            onOpenCatalog: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 anuncios encontrados'), findsOneWidget);
    expect(find.text('PUBLICACIÓN VENCIDA'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'cocina');
    await tester.pump();

    expect(find.text('1 anuncios encontrados'), findsOneWidget);
    expect(find.text('AYUDANTE DE COCINA'), findsOneWidget);
    expect(find.text('ANALISTA DE EXPERIENCIAS'), findsNothing);
  });

  testWidgets('employment filters can be applied and cleared', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmploymentScreen(
            repository: _FakeRecruitmentRepository(_sampleJobs),
            onOpenCatalog: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo ofertas con salario publicado'));
    await tester.ensureVisible(find.text('Aplicar filtros'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(find.text('1 anuncios encontrados · 1 filtros'), findsOneWidget);
    expect(find.text('ANALISTA DE EXPERIENCIAS'), findsOneWidget);
    expect(find.text('AYUDANTE DE COCINA'), findsNothing);

    await tester.tap(find.text('Limpiar búsqueda y filtros'));
    await tester.pumpAndSettle();
    expect(find.text('2 anuncios encontrados'), findsOneWidget);
  });

  testWidgets('employment detail retains public company information', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmploymentScreen(
            repository: _FakeRecruitmentRepository(_sampleJobs),
            onOpenCatalog: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANALISTA DE EXPERIENCIAS'));
    await tester.pumpAndSettle();

    expect(find.text('DETALLE DE LA OFERTA'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('empleos@ejemplo.bo'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('empleos@ejemplo.bo'), findsOneWidget);
    expect(find.text('Funciones y responsabilidades'), findsOneWidget);
  });

  testWidgets('student profile suggestions appear above the catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmploymentScreen(
            repository: _FakeRecruitmentRepository(_sampleJobs),
            onOpenCatalog: () {},
            showSuggestions: true,
            profile: const UserProfile(
              uid: 'user-1',
              fullName: 'Ana',
              email: 'ana@example.com',
              phone: '',
              city: 'La Paz',
              areaOfInterest: 'Tecnología',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUGERIDAS PARA TI'), findsOneWidget);
    expect(find.text('Según tu perfil, no según el filtro de búsqueda.'), findsOneWidget);
    expect(find.text('ANALISTA DE EXPERIENCIAS'), findsWidgets);
    expect(find.textContaining('Coincide tu área Tecnología'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'cocina');
    await tester.pump();
    expect(find.text('SUGERIDAS PARA TI'), findsOneWidget);
    expect(find.text('AYUDANTE DE COCINA'), findsOneWidget);
    expect(find.textContaining('Coincide tu área Tecnología'), findsOneWidget);
  });

  testWidgets('incomplete profile shows complete-profile call to action', (
    tester,
  ) async {
    var openedAccount = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmploymentScreen(
            repository: _FakeRecruitmentRepository(_sampleJobs),
            onOpenCatalog: () {},
            showSuggestions: true,
            profile: const UserProfile(
              uid: 'user-1',
              fullName: 'Ana',
              email: 'ana@example.com',
              phone: '',
              city: '',
              areaOfInterest: '',
            ),
            onCompleteProfile: () => openedAccount = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Completar perfil'), findsOneWidget);
    await tester.tap(find.text('Completar perfil'));
    expect(openedAccount, isTrue);
  });

  testWidgets('company accounts do not see the suggestions block', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          authRepository: _SignedInAuthRepository(),
          profileRepository: _EmptyProfileRepository(),
          recruitmentRepository: _FakeRecruitmentRepository(_sampleJobs),
          institutionRepository: _EmptyInstitutionRepository(),
          accountType: 'company',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUGERIDAS PARA TI'), findsNothing);
    expect(find.text('ANUNCIOS DE EMPLEOS ACTIVOS'), findsOneWidget);
  });
}

final _sampleJobs = [
  JobPosting(
    id: 'job-1',
    companyId: 'company-1',
    ownerUid: 'owner-1',
    companyName: 'Sociedad Administradora S.A.',
    companySector: 'Consultoría',
    companyEmail: 'empleos@ejemplo.bo',
    companyPhone: '+591 70000000',
    companyWebsite: '',
    companyAddress: 'La Paz',
    title: 'Analista de experiencias',
    description: 'Analiza experiencias de usuarios.',
    responsibilities: 'Gestionar análisis de usuarios.',
    requirements: 'Experiencia en investigación.',
    area: 'Tecnología',
    city: 'La Paz',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: '1 a 2 años',
    education: '',
    salaryMinimum: 4000,
    salaryMaximum: 6000,
    currency: 'BOB',
    createdAt: DateTime(2026, 9, 25),
    deadline: null,
    status: 'published',
  ),
  JobPosting(
    id: 'job-2',
    companyId: 'company-2',
    ownerUid: 'owner-2',
    companyName: 'Empresa de servicios',
    companySector: 'Gastronomía',
    companyEmail: '',
    companyPhone: '',
    companyWebsite: '',
    companyAddress: '',
    title: 'Ayudante de cocina',
    description: 'Apoyo en cocina y preparación de alimentos.',
    responsibilities: '',
    requirements: '',
    area: 'Gastronomía',
    city: 'Cochabamba',
    modality: 'Presencial',
    employmentType: 'Medio tiempo',
    experience: 'Sin experiencia',
    education: '',
    salaryMinimum: null,
    salaryMaximum: null,
    currency: 'BOB',
    createdAt: DateTime(2026, 9, 24),
    deadline: null,
    status: 'published',
  ),
  JobPosting(
    id: 'job-expired',
    companyId: 'company-3',
    ownerUid: 'owner-3',
    companyName: 'Empresa con plazo vencido',
    companySector: '',
    companyEmail: '',
    companyPhone: '',
    companyWebsite: '',
    companyAddress: '',
    title: 'Publicación vencida',
    description: 'Esta publicación ya superó su fecha límite.',
    responsibilities: '',
    requirements: '',
    area: 'Administración',
    city: 'La Paz',
    modality: 'Presencial',
    employmentType: 'Temporal',
    experience: 'No especificada',
    education: '',
    salaryMinimum: null,
    salaryMaximum: null,
    currency: 'BOB',
    createdAt: DateTime(2026, 10, 20),
    deadline: DateTime(2026, 10, 21),
    status: 'published',
  ),
];

class _FakeRecruitmentRepository implements RecruitmentRepository {
  _FakeRecruitmentRepository(this.jobs);

  final List<JobPosting> jobs;

  @override
  Stream<Company?> watchCompany(String ownerUid) => Stream.value(null);

  @override
  Future<void> saveCompany(Company company) async {}

  @override
  Stream<List<JobPosting>> watchPublicJobs() => Stream.value(jobs);

  @override
  Stream<List<JobPosting>> watchCompanyJobs(String ownerUid) =>
      Stream.value(jobs.where((job) => job.ownerUid == ownerUid).toList());

  @override
  Future<String> saveJob(JobPosting job) async => job.id;

  @override
  Future<void> updateJobStatus(String jobId, String status) async {}
}

class _SignedInAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream.value(currentUser);

  @override
  User? get currentUser => _FakeUser();

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeUser implements User {
  @override
  String get uid => 'authenticated-user';

  @override
  String? get email => 'user@example.com';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfile?> getProfile(String uid) async => null;

  @override
  Stream<UserProfile?> watchProfile(String uid) => Stream.value(null);

  @override
  Future<void> updateVisibility({
    required String uid,
    required bool isVisible,
  }) async {}

  @override
  Future<void> saveProfile({
    required UserProfile profile,
    PlatformFile? cvFile,
  }) async {}
}

class _EmptyInstitutionRepository implements InstitutionRepository {
  @override
  Stream<Institution?> watchInstitution(String uid) => Stream.value(null);

  @override
  Future<void> saveInstitutionRequest(Institution institution) async {}

  @override
  Stream<List<InstitutionCourse>> watchInstitutionCourses(String uid) =>
      Stream.value(const []);

  @override
  Stream<List<InstitutionCourse>> watchPublishedCourses() =>
      Stream.value(const []);

  @override
  Future<String> saveCourse(InstitutionCourse course) async => course.id;

  @override
  Future<void> retireCourse({
    required String courseId,
    required String ownerUid,
  }) async {}
}
