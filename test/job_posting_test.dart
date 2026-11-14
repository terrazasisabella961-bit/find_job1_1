import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/models/job_posting.dart';

void main() {
  test(
    'job posting preserves the publication form data in Firestore shape',
    () {
      final createdAt = DateTime(2026, 10, 4);
      final publicationDate = DateTime(2026, 10, 5);
      final deadline = DateTime(2026, 11, 4);
      final job = JobPosting(
        id: 'job-1',
        companyId: 'company-1',
        ownerUid: 'company-1',
        companyName: 'Empresa de prueba',
        companySector: 'Reclutamiento',
        companyEmail: 'talento@empresa.bo',
        companyPhone: '',
        companyWebsite: 'https://empresa.bo',
        companyAddress: 'Santa Cruz, Equipetrol',
        title: 'Desarrollador',
        description: 'Responsabilidades del puesto',
        responsibilities: '',
        requirements: 'CV actualizado',
        area: 'Tecnología y Software',
        city: 'Santa Cruz de la Sierra',
        modality: 'Híbrida',
        employmentType: 'Tiempo completo',
        experience: 'Semi Senior (3-5 años)',
        education: 'Licenciatura / Egresado',
        salaryMinimum: 7000,
        salaryMaximum: 10500,
        currency: 'BOB',
        createdAt: createdAt,
        deadline: deadline,
        status: 'published',
        zone: 'Equipetrol',
        requiredDocuments: const ['CV actualizado', 'Pretensión salarial'],
        skills: const ['Dart', 'Flutter'],
        salaryConfidential: false,
        benefits: const ['Seguro de Salud Privado'],
        publicationDate: publicationDate,
        vacancyCount: 2,
        applicationChannel: 'email',
        contactEmail: 'talento@empresa.bo',
        whatsApp: '+591 77000000',
      );

      final firestoreData = {
        ...job.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
      final restored = JobPosting.fromMap('job-1', firestoreData);

      expect(restored.ownerUid, 'company-1');
      expect(restored.currency, 'BOB');
      expect(restored.zone, 'Equipetrol');
      expect(restored.requiredDocuments, job.requiredDocuments);
      expect(restored.skills, job.skills);
      expect(restored.salaryConfidential, isFalse);
      expect(restored.benefits, job.benefits);
      expect(restored.publicationDate, publicationDate);
      expect(restored.deadline, deadline);
      expect(restored.vacancyCount, 2);
      expect(restored.applicationChannel, 'email');
      expect(restored.contactEmail, 'talento@empresa.bo');
      expect(restored.whatsApp, '+591 77000000');
    },
  );
}
