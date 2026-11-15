import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/models/company.dart';
import 'package:find_job1_1/src/models/job_posting.dart';
import 'package:find_job1_1/src/screens/recruitment_screen.dart';
import 'package:find_job1_1/src/services/recruitment_repository.dart';

void main() {
  testWidgets('job save prevents duplicate taps and clears loading on error', (
    tester,
  ) async {
    final repository = _PendingRecruitmentRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: JobFormScreen(company: _company, repository: repository),
      ),
    );

    await tester.enterText(_formField('job-title'), 'Desarrollador Flutter');
    final description = _formField('job-description');
    await tester.scrollUntilVisible(
      description,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(description, 'Desarrollar aplicaciones móviles.');
    final publishButton = find.text('Publicar Convocatoria Laboral');
    await tester.scrollUntilVisible(
      publishButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(publishButton);
    await tester.pump();

    expect(repository.saveCalls, 1);
    expect(find.text('Publicando...'), findsOneWidget);

    final loadingButton = find.text('Publicando...');
    await tester.ensureVisible(loadingButton);
    await tester.tap(loadingButton);
    await tester.pump();
    expect(repository.saveCalls, 1);

    repository.pendingSave.completeError(StateError('Permiso denegado'));
    await tester.pumpAndSettle();

    expect(find.text('Permiso denegado'), findsOneWidget);
    expect(find.text('Publicar Convocatoria Laboral'), findsOneWidget);
  });
}

const _company = Company(
  id: 'company-uid',
  ownerUid: 'company-uid',
  name: 'Empresa de prueba',
  taxId: '',
  sector: 'Tecnología',
  description: '',
  email: 'talento@empresa.bo',
  phone: '',
  city: 'La Paz',
  address: '',
  website: '',
);

class _PendingRecruitmentRepository implements RecruitmentRepository {
  final pendingSave = Completer<String>();
  int saveCalls = 0;

  @override
  Stream<Company?> watchCompany(String ownerUid) => const Stream.empty();

  @override
  Future<void> saveCompany(Company company) async {}

  @override
  Stream<List<JobPosting>> watchPublicJobs() => const Stream.empty();

  @override
  Stream<List<JobPosting>> watchCompanyJobs(String ownerUid) =>
      const Stream.empty();

  @override
  Future<String> saveJob(JobPosting job) {
    saveCalls++;
    return pendingSave.future;
  }

  @override
  Future<void> updateJobStatus(String jobId, String status) async {}
}

Finder _formField(String key) => find.byWidgetPredicate(
  (widget) => widget is TextFormField && widget.key == ValueKey<String>(key),
);
