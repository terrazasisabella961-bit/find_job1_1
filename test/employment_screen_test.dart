import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/models/company.dart';
import 'package:find_job1_1/src/models/job_posting.dart';
import 'package:find_job1_1/src/screens/employment_screen.dart';
import 'package:find_job1_1/src/services/recruitment_repository.dart';

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
