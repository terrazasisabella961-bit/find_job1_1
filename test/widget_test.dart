import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_job1_1/main.dart';
import 'package:find_job1_1/src/models/user_profile.dart';
import 'package:find_job1_1/src/models/institution.dart';
import 'package:find_job1_1/src/models/institution_course.dart';
import 'package:find_job1_1/src/screens/institution_portal_screen.dart';
import 'package:find_job1_1/src/screens/course_catalog_screen.dart';
import 'package:find_job1_1/src/screens/account_screen.dart';
import 'package:find_job1_1/src/screens/recruitment_screen.dart';
import 'package:find_job1_1/src/screens/user_registration_screen.dart';
import 'package:find_job1_1/src/services/auth_repository.dart';
import 'package:find_job1_1/src/services/institution_repository.dart';
import 'package:find_job1_1/src/widgets/app_bottom_navigation.dart';
import 'package:find_job1_1/src/models/company.dart';
import 'package:find_job1_1/src/models/job_posting.dart';
import 'package:find_job1_1/src/services/recruitment_repository.dart';
import 'package:find_job1_1/src/services/user_profile_repository.dart';

void main() {
  testWidgets(
    'unauthenticated users start at login and cannot open private tabs',
    (WidgetTester tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pump();

      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      await tester.tap(find.text('Cuenta'));
      await tester.pump();
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(
        find.text('Inicia sesión para acceder a esta sección.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Instituciones'));
      await tester.pumpAndSettle();
      expect(find.text('REGISTRO DE INSTITUCIÓN'), findsOneWidget);
    },
  );

  testWidgets(
    'successful login opens Employment and preserves session on tabs',
    (WidgetTester tester) async {
      final auth = _SignInAuthRepository();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MyApp(
          authRepository: auth,
          profileRepository: _FakeUserProfileRepository(),
          recruitmentRepository: _FakeRecruitmentRepository(),
          institutionRepository: _FakeInstitutionRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'secret123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('ANUNCIOS DE EMPLEOS ACTIVOS'), findsOneWidget);
      expect(find.text('REGISTRO DE USUARIO'), findsNothing);

      await tester.tap(find.text('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('MI CUENTA'), findsOneWidget);
      expect(find.text('REGISTRO DE USUARIO'), findsNothing);

      await tester.tap(find.text('Reclutar'));
      await tester.pumpAndSettle();
      expect(find.text('Acceso para empresas'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      await tester.tap(find.text('Instituciones'));
      await tester.pumpAndSettle();
      expect(find.text('Acceso institucional'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      await tester.tap(find.text('Extras'));
      await tester.pumpAndSettle();
      expect(find.text('EXTRAS'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      await tester.tap(find.text('Cursos'));
      await tester.pumpAndSettle();
      expect(find.text('CURSOS Y POSGRADOS'), findsOneWidget);
      expect(find.text('0 programas encontrados'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      await tester.tap(find.text('Empleo'));
      await tester.pumpAndSettle();
      expect(find.text('ANUNCIOS DE EMPLEOS ACTIVOS'), findsOneWidget);

      await tester.tap(find.text('Cuenta'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cerrar sesión'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    },
  );

  testWidgets('institution login opens the private institution dashboard', (
    WidgetTester tester,
  ) async {
    final auth = _SignInAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: InstitutionPortalScreen(
          authRepository: auth,
          repository: _FakeInstitutionRepository(
            institution: _sampleInstitution(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('ACCESO INSTITUCIONAL'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Iniciar sesión'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MI INSTITUCIÓN'), findsOneWidget);
    expect(find.text('Institución de prueba'), findsOneWidget);
  });

  testWidgets(
    'company registration opens dashboard only after the save succeeds',
    (WidgetTester tester) async {
      final repository = _FakeRecruitmentRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecruitmentScreen(
              ownerUid: 'company-owner',
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('REGISTRO DE EMPRESA'), findsOneWidget);

      await _completeCompanyForm(tester);
      await tester.pumpAndSettle();

      expect(repository.savedCompany, isNotNull);
      expect(find.text('MI EMPRESA'), findsOneWidget);
      expect(find.text('Publicar nuevo empleo o vacante'), findsOneWidget);
    },
  );

  testWidgets(
    'company login can complete a missing profile and open its dashboard',
    (WidgetTester tester) async {
      final auth = _SignInAuthRepository();
      final repository = _FakeRecruitmentRepository();
      addTearDown(auth.dispose);
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MyApp(
          authRepository: auth,
          profileRepository: _FakeUserProfileRepository(),
          recruitmentRepository: repository,
          institutionRepository: _FakeInstitutionRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reclutar'));
      await tester.pumpAndSettle();
      final loginFields = find.byType(TextField);
      await tester.enterText(loginFields.at(0), 'user@example.com');
      await tester.enterText(loginFields.at(1), '1023456028');
      await tester.enterText(loginFields.at(2), 'secret123');
      await tester.tap(find.textContaining('Iniciar Sesión Corporativa'));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNotNull);
      expect(
        find.textContaining('no encontramos un perfil de empresa'),
        findsOneWidget,
      );
      await tester.tap(find.text('Completar perfil de empresa'));
      await tester.pumpAndSettle();
      await _completeCompanyForm(tester);
      await tester.pumpAndSettle();

      expect(repository.savedCompany?.ownerUid, 'authenticated-user');
      expect(find.text('MI EMPRESA'), findsOneWidget);
      expect(find.text('Publicar nuevo empleo o vacante'), findsOneWidget);
      expect(auth.currentUser, isNotNull);

      await tester.tap(find.text('Publicar nuevo empleo o vacante'));
      await tester.pumpAndSettle();
      expect(find.text('PUBLICAR EMPLEO O VACANTE'), findsOneWidget);
    },
  );

  testWidgets('company login with an existing profile opens its dashboard', (
    WidgetTester tester,
  ) async {
    final auth = _SignInAuthRepository();
    final repository = _FakeRecruitmentRepository(
      savedCompany: const Company(
        id: 'authenticated-user',
        ownerUid: 'authenticated-user',
        name: 'Empresa de prueba',
        taxId: '1023456028',
        sector: 'Tecnología',
        description: '',
        email: 'user@example.com',
        phone: '',
        city: 'La Paz',
        address: 'Centro',
        website: '',
      ),
    );
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MyApp(
        authRepository: auth,
        profileRepository: _FakeUserProfileRepository(),
        recruitmentRepository: repository,
        institutionRepository: _FakeInstitutionRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reclutar'));
    await tester.pumpAndSettle();
    final loginFields = find.byType(TextField);
    await tester.enterText(loginFields.at(0), 'user@example.com');
    await tester.enterText(loginFields.at(1), '1023456028');
    await tester.enterText(loginFields.at(2), 'secret123');
    await tester.tap(find.textContaining('Iniciar Sesión Corporativa'));
    await tester.pumpAndSettle();

    expect(find.text('MI EMPRESA'), findsOneWidget);
    expect(find.text('Publicar nuevo empleo o vacante'), findsOneWidget);
    expect(auth.currentUser, isNotNull);
  });

  testWidgets('company save failure keeps registration form open', (
    WidgetTester tester,
  ) async {
    final repository = _FakeRecruitmentRepository(failCompanySave: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecruitmentScreen(
            ownerUid: 'company-owner',
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _completeCompanyForm(tester);
    await tester.pumpAndSettle();

    expect(repository.savedCompany, isNull);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('MI EMPRESA'), findsNothing);
  });

  testWidgets(
    'restored authenticated session with no profile opens Employment',
    (WidgetTester tester) async {
      final auth = _SignInAuthRepository(initialUser: _FakeUser());
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MyApp(
          authRepository: auth,
          profileRepository: _FakeUserProfileRepository(),
          recruitmentRepository: _FakeRecruitmentRepository(),
          institutionRepository: _FakeInstitutionRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ANUNCIOS DE EMPLEOS ACTIVOS'), findsOneWidget);
      expect(find.text('REGISTRO DE USUARIO'), findsNothing);
      await tester.tap(find.text('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('MI CUENTA'), findsOneWidget);
      expect(find.text('REGISTRO DE USUARIO'), findsNothing);
    },
  );

  testWidgets('account profile error can retry without ending the session', (
    WidgetTester tester,
  ) async {
    final auth = _SignInAuthRepository(initialUser: _FakeUser());
    final profiles = _RetryingUserProfileRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountScreen(
            authRepository: auth,
            profileRepository: profiles,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión sigue activa'), findsOneWidget);
    expect(profiles.requestedUids, ['authenticated-user']);
    expect(auth.currentUser, isNotNull);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('MI CUENTA'), findsOneWidget);
    expect(find.text('Perfil de prueba'), findsOneWidget);
    expect(profiles.requestedUids, [
      'authenticated-user',
      'authenticated-user',
    ]);
    expect(auth.currentUser, isNotNull);
  });

  testWidgets('six navigation items remain accessible at mobile width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigation(
            selectedIndex: selectedIndex,
            onSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    for (final label in [
      'Empleo',
      'Reclutar',
      'Instituciones',
      'Cuenta',
      'Cursos',
      'Extras',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Cursos'));
    expect(selectedIndex, 4);
  });

  testWidgets('login validates email and password and toggles visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    final passwordField = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(TextField),
      ),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(TextFormField).last,
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isFalse,
    );
  });

  testWidgets('registration preserves all fields and validates before submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('REGISTRO DE USUARIO'), findsOneWidget);
    expect(find.text('Nombre y apellidos'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Teléfono / WhatsApp'), findsOneWidget);
    expect(find.text('Ciudad de residencia'), findsOneWidget);
    expect(find.text('Área profesional o de interés'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Currículum Vitae (CV)'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Currículum Vitae (CV)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Confirmar contraseña'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Confirmar contraseña'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Acepto los '),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Acepto los '), findsOneWidget);

    await tester.ensureVisible(find.text('Registrarme'));
    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();
    expect(find.text('El nombre es obligatorio.'), findsOneWidget);
  });

  testWidgets('registration preserves a saved city outside current options', (
    WidgetTester tester,
  ) async {
    const legacyCity = 'La Paz, Bolivia';
    await tester.pumpWidget(
      MaterialApp(
        home: UserRegistrationScreen(
          authRepository: _FakeAuthRepository(),
          profileRepository: _FakeUserProfileRepository(),
          initialProfile: const UserProfile(
            uid: 'user-1',
            fullName: 'Ana Ejemplo',
            email: 'ana@example.com',
            phone: '+591 70000000',
            city: legacyCity,
            areaOfInterest: 'Tecnología',
            acceptedTerms: true,
          ),
          isEditing: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cityDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(cityDropdown.initialValue, legacyCity);
    final dropdownButton = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<String>),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    final cityOptions = dropdownButton.items!
        .map((item) => item.value)
        .toList();
    expect(cityOptions.where((city) => city == legacyCity), hasLength(1));
    expect(cityOptions.toSet(), hasLength(cityOptions.length));
  });

  testWidgets('catalog remains accessible from authenticated area navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: CourseCatalogScreen(
              onOpenAccount: () {},
              courseRepository: _FakeInstitutionRepository(
                publishedCourses: [
                  _samplePublishedCourse(),
                  _samplePublishedCourse(
                    id: 'draft',
                    title: 'Curso borrador',
                    status: 'draft',
                  ),
                  _samplePublishedCourse(
                    id: 'expired',
                    title: 'Curso vencido',
                    deadline: DateTime.now().subtract(const Duration(days: 1)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CURSOS Y POSGRADOS'), findsOneWidget);
    expect(find.text('1 programas encontrados'), findsOneWidget);
    expect(find.text('CURSO REAL DE PRUEBA'), findsOneWidget);
    expect(find.text('CURSO BORRADOR'), findsNothing);
    expect(find.text('CURSO VENCIDO'), findsNothing);
    await tester.tap(find.text('CURSO REAL DE PRUEBA'));
    await tester.pumpAndSettle();
    expect(find.text('INSTITUTO DE PRUEBA'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Descripción'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Descripción'), findsOneWidget);
  });
}

MyApp _testApp() {
  return MyApp(
    authRepository: _FakeAuthRepository(),
    profileRepository: _FakeUserProfileRepository(),
    recruitmentRepository: _FakeRecruitmentRepository(),
    institutionRepository: _FakeInstitutionRepository(),
  );
}

class _FakeInstitutionRepository implements InstitutionRepository {
  _FakeInstitutionRepository({
    this.publishedCourses = const [],
    this.institution,
  });

  final List<InstitutionCourse> publishedCourses;
  final Institution? institution;

  @override
  Stream<Institution?> watchInstitution(String uid) =>
      Stream.value(institution?.uid == uid ? institution : null);

  @override
  Future<void> saveInstitutionRequest(Institution institution) async {}

  @override
  Stream<List<InstitutionCourse>> watchInstitutionCourses(String uid) =>
      Stream.value(const []);

  @override
  Stream<List<InstitutionCourse>> watchPublishedCourses() =>
      Stream.value(publishedCourses);

  @override
  Future<String> saveCourse(InstitutionCourse course) async => course.id;

  @override
  Future<void> retireCourse({
    required String courseId,
    required String ownerUid,
  }) async {}
}

Institution _sampleInstitution() => const Institution(
  uid: 'authenticated-user',
  legalName: 'Institución de prueba S.R.L.',
  displayName: 'Institución de prueba',
  type: 'Universidad',
  taxId: '100000',
  accreditation: 'RM-100',
  country: 'Bolivia',
  city: 'La Paz',
  address: 'Av. de prueba',
  website: 'https://example.com',
  primaryDomain: 'example.com',
  secondaryDomains: [],
  representativeName: 'Persona de prueba',
  representativeRole: 'Rectora',
  phone: '+59170000000',
  contactEmail: 'contacto@example.com',
  adminEmail: 'user@example.com',
  verificationStatus: 'pending',
  twoFactorRequested: false,
);

InstitutionCourse _samplePublishedCourse({
  String id = 'live-course',
  String title = 'Curso real de prueba',
  String status = 'published',
  DateTime? deadline,
}) => InstitutionCourse(
  id: id,
  ownerUid: 'institution-1',
  institutionName: 'Instituto de Prueba',
  institutionLocation: 'La Paz, Bolivia',
  title: title,
  programType: 'Curso corto',
  studyArea: 'Tecnología y Software',
  modality: 'Online / Virtual (En vivo)',
  duration: '4 semanas',
  description: 'Curso disponible para consultar.',
  totalSeats: 20,
  minimumLevel: 'Bachillerato',
  requiredDocuments: const [],
  currency: 'BOB (Bs.)',
  totalCost: 0,
  paymentPlan: '',
  earlyDiscount: '',
  includesCertification: true,
  publicationDate: DateTime.now().subtract(const Duration(days: 1)),
  applicationDeadline: deadline ?? DateTime.now().add(const Duration(days: 30)),
  startDate: DateTime.now().add(const Duration(days: 45)),
  whatsApp: '+59170000000',
  admissionsEmail: 'admisiones@instituto.edu.bo',
  brochureUrl: null,
  status: status,
  createdAt: DateTime.now(),
);

Future<void> _completeCompanyForm(WidgetTester tester) async {
  Future<void> fill(String hint, String value) async {
    final field = find.ancestor(
      of: find.text(hint),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(
      field,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field, value);
  }

  await fill('Empresa o entidad del puesto', 'Empresa de prueba');
  await fill('Ej. Reclutador', 'Reclutadora');
  await fill('NIT de la empresa o No. de carnet de la entidad', '1023456028');
  await tester.scrollUntilVisible(
    find.text('Guardar'),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Guardar'));
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class _FakeUserProfileRepository implements UserProfileRepository {
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

class _RetryingUserProfileRepository implements UserProfileRepository {
  final requestedUids = <String>[];
  var _attempts = 0;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    requestedUids.add(uid);
    _attempts++;
    if (_attempts == 1) throw StateError('temporary offline');
    return const UserProfile(
      uid: 'authenticated-user',
      fullName: 'Perfil de prueba',
      email: 'user@example.com',
      phone: '',
      city: '',
      areaOfInterest: '',
    );
  }

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

class _SignInAuthRepository implements AuthRepository {
  _SignInAuthRepository({User? initialUser}) : _currentUser = initialUser;

  final _authStateController = StreamController<User?>.broadcast(sync: true);
  User? _currentUser;

  @override
  Stream<User?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _currentUser = _FakeUser();
    _authStateController.add(_currentUser);
    return _FakeUserCredential();
  }

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
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<void> dispose() => _authStateController.close();
}

class _FakeUser implements User {
  @override
  String get uid => 'authenticated-user';

  @override
  String? get displayName => 'Authenticated User';

  @override
  String? get email => 'user@example.com';

  @override
  bool get emailVerified => true;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRecruitmentRepository implements RecruitmentRepository {
  _FakeRecruitmentRepository({
    this.failCompanySave = false,
    this.savedCompany,
  });

  final bool failCompanySave;
  final _companyController = StreamController<Company?>.broadcast(sync: true);
  Company? savedCompany;

  @override
  Stream<Company?> watchCompany(String ownerUid) async* {
    yield savedCompany;
    yield* _companyController.stream;
  }

  @override
  Future<void> saveCompany(Company company) async {
    if (failCompanySave) throw Exception('Firestore write failed');
    savedCompany = company;
    _companyController.add(company);
  }

  Future<void> dispose() => _companyController.close();

  @override
  Stream<List<JobPosting>> watchPublicJobs() => Stream.value(const []);

  @override
  Stream<List<JobPosting>> watchCompanyJobs(String ownerUid) =>
      Stream.value(const []);

  @override
  Future<String> saveJob(JobPosting job) async => job.id;

  @override
  Future<void> updateJobStatus(String jobId, String status) async {}
}
