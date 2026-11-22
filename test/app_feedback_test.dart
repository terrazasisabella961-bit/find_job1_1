import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/models/institution.dart';
import 'package:find_job1_1/src/models/institution_course.dart';
import 'package:find_job1_1/src/screens/institution_portal_screen.dart';
import 'package:find_job1_1/src/services/institution_repository.dart';
import 'package:find_job1_1/src/widgets/app_feedback.dart';

void main() {
  testWidgets('form feedback is readable on the dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppMessage(
                context,
                'El curso se publicó en el catálogo.',
                kind: AppMessageKind.success,
              ),
              child: const Text('Mostrar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pump();

    expect(find.text('El curso se publicó en el catálogo.'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, isNot(const Color(0xFF1A172F)));
  });

  testWidgets('empty course form shows an error instead of failing silently', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InstitutionCourseFormScreen(
            institution: _institution,
            repository: _FakeCourseRepository(),
            onBack: () {},
          ),
        ),
      ),
    );

    final publish = find.text('Publicar Convocatoria Ahora');
    await tester.scrollUntilVisible(
      publish,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(publish);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Revisa los campos obligatorios'),
      findsOneWidget,
    );
  });
}

const _institution = Institution(
  uid: 'institution-1',
  legalName: 'Instituto de prueba',
  displayName: 'Instituto de prueba',
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
  adminEmail: 'admin@example.com',
  verificationStatus: 'verified',
  twoFactorRequested: false,
);

class _FakeCourseRepository implements InstitutionRepository {
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

  @override
  Future<void> publishCourse({
    required String courseId,
    required String ownerUid,
  }) async {}
}
