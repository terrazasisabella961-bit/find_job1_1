import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/models/job_posting.dart';
import 'package:find_job1_1/src/models/user_profile.dart';
import 'package:find_job1_1/src/services/job_suggestion_service.dart';

void main() {
  const service = LocalJobSuggestionService();
  final now = DateTime(2026, 11, 20);

  test('Tecnología + La Paz ranks the matching job above a different city/area', () {
    const profile = UserProfile(
      uid: 'user-1',
      fullName: 'Ana',
      email: 'ana@example.com',
      phone: '',
      city: 'La Paz',
      areaOfInterest: 'Tecnología',
    );
    final localMatch = _job(
      id: 'local-tech',
      title: 'Desarrolladora Flutter',
      area: 'Tecnología',
      city: 'La Paz',
    );
    final other = _job(
      id: 'other',
      title: 'Ayudante de cocina',
      area: 'Gastronomía',
      city: 'Cochabamba',
      sector: 'Gastronomía',
    );

    final suggestions = service.suggest(
      profile: profile,
      jobs: [other, localMatch],
      now: now,
    );

    expect(suggestions, isNotEmpty);
    expect(suggestions.first.job.id, 'local-tech');
    expect(suggestions.first.score, greaterThan(suggestions.length > 1 ? suggestions.last.score : 0));
    expect(
      suggestions.first.reasons,
      containsAll(['Coincide tu área Tecnología', 'Misma ciudad: La Paz']),
    );
    expect(suggestions.any((item) => item.job.id == 'other'), isFalse);
  });

  test('empty or missing profile does not invent suggestions', () {
    final jobs = [
      _job(id: 'job-1', title: 'Analista', area: 'Tecnología', city: 'La Paz'),
    ];

    expect(service.suggest(profile: null, jobs: jobs, now: now), isEmpty);
    expect(
      service.suggest(
        profile: const UserProfile(
          uid: 'user-1',
          fullName: 'Ana',
          email: 'ana@example.com',
          phone: '',
          city: '',
          areaOfInterest: '',
        ),
        jobs: jobs,
        now: now,
      ),
      isEmpty,
    );
  });

  test('expired and unpublished jobs are excluded', () {
    const profile = UserProfile(
      uid: 'user-1',
      fullName: 'Ana',
      email: 'ana@example.com',
      phone: '',
      city: 'La Paz',
      areaOfInterest: 'Tecnología',
    );
    final expired = _job(
      id: 'expired',
      title: 'Vencida',
      area: 'Tecnología',
      city: 'La Paz',
      deadline: DateTime(2026, 10, 21),
    );
    final draft = _job(
      id: 'draft',
      title: 'Borrador',
      area: 'Tecnología',
      city: 'La Paz',
      status: 'draft',
    );

    expect(
      service.suggest(profile: profile, jobs: [expired, draft], now: now),
      isEmpty,
    );
  });

  test('remote jobs are not penalized for a different city', () {
    const profile = UserProfile(
      uid: 'user-1',
      fullName: 'Ana',
      email: 'ana@example.com',
      phone: '',
      city: 'La Paz',
      areaOfInterest: 'Tecnología',
    );
    final remote = _job(
      id: 'remote',
      title: 'Backend remoto',
      area: 'Tecnología',
      city: 'Santa Cruz de la Sierra',
      modality: 'Remota',
    );

    final suggestions = service.suggest(
      profile: profile,
      jobs: [remote],
      now: now,
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.reasons, contains('Modalidad remota, no exige tu ciudad'));
  });

  test('matching skills rank a job above an otherwise similar listing', () {
    const profile = UserProfile(
      uid: 'user-1',
      fullName: 'Ana',
      email: 'ana@example.com',
      phone: '',
      city: 'La Paz',
      areaOfInterest: 'Tecnología',
      skills: ['Informática', 'Ofimática'],
    );
    final match = _job(
      id: 'skills-match',
      title: 'Soporte técnico',
      area: 'Tecnología',
      city: 'La Paz',
      skills: const ['Informática', 'Atención al cliente'],
    );
    final miss = _job(
      id: 'skills-miss',
      title: 'Analista junior',
      area: 'Tecnología',
      city: 'La Paz',
      skills: const ['Ventas'],
    );

    final suggestions = service.suggest(
      profile: profile,
      jobs: [miss, match],
      now: now,
    );

    expect(suggestions, isNotEmpty);
    expect(suggestions.first.job.id, 'skills-match');
    expect(
      suggestions.first.reasons,
      contains('Coincide una habilidad de tu perfil'),
    );
  });
}

JobPosting _job({
  required String id,
  required String title,
  required String area,
  required String city,
  String status = 'published',
  String modality = 'Presencial',
  String sector = 'Consultoría',
  List<String> skills = const [],
  DateTime? deadline,
}) {
  return JobPosting(
    id: id,
    companyId: 'company-1',
    ownerUid: 'owner-1',
    companyName: 'Empresa de prueba',
    companySector: sector,
    companyEmail: '',
    companyPhone: '',
    companyWebsite: '',
    companyAddress: city,
    title: title,
    description: title,
    responsibilities: '',
    requirements: '',
    area: area,
    city: city,
    modality: modality,
    employmentType: 'Tiempo completo',
    experience: '',
    education: '',
    salaryMinimum: null,
    salaryMaximum: null,
    skills: skills,
    currency: 'BOB',
    createdAt: DateTime(2026, 11, 1),
    deadline: deadline,
    status: status,
  );
}
