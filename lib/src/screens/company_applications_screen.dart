import 'package:flutter/material.dart';

import '../config/file_upload_mode.dart';
import '../config/simulated_cv.dart';
import '../models/job_application.dart';
import '../models/job_posting.dart';
import '../widgets/app_bottom_navigation.dart';

class CompanyApplicationsScreen extends StatelessWidget {
  const CompanyApplicationsScreen({
    required this.job,
    required this.applications,
    super.key,
  });

  final JobPosting job;
  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context) {
    final items = applications
        .where((item) => item.jobId == job.id)
        .toList();
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: appTextColor),
                ),
                Expanded(
                  child: Text(
                    'POSTULANTES',
                    style: TextStyle(
                      color: appTextColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              job.title,
              style: TextStyle(
                color: appTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${items.length} ficha${items.length == 1 ? '' : 's'} recibida${items.length == 1 ? '' : 's'}',
              style: TextStyle(color: appMutedColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                'Aún no hay postulaciones para esta oferta.',
                style: TextStyle(color: appMutedColor),
              )
            else
              for (final application in items)
                _ApplicantCard(application: application),
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            application.fullName,
            style: TextStyle(
              color: appTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              application.city,
              application.areaOfInterest,
              application.availability,
            ].where((item) => item.trim().isNotEmpty).join(' · '),
            style: TextStyle(color: appMutedColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            application.email,
            style: TextStyle(color: appTextColor, fontSize: 12),
          ),
          Text(
            application.phone,
            style: TextStyle(color: appTextColor, fontSize: 12),
          ),
          if (application.educationLevel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              application.educationLevel,
              style: TextStyle(color: appMutedColor, fontSize: 12),
            ),
          ],
          if (application.careerTitle.isNotEmpty)
            Text(
              application.careerTitle,
              style: TextStyle(color: appMutedColor, fontSize: 12),
            ),
          if (application.skills.isNotEmpty)
            Text(
              application.skills.join(', '),
              style: TextStyle(color: appMutedColor, fontSize: 12),
            ),
          if (application.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              application.message,
              style: TextStyle(color: appTextColor, fontSize: 12, height: 1.35),
            ),
          ],
          if (application.cvFileName != null &&
              application.cvFileName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: simulateFileUploads
                  ? () => showSimulatedCvScreen(
                      context,
                      heading: 'CV de ${application.fullName}',
                      detail: application.cvFileName!,
                    )
                  : null,
              icon: Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: Text(application.cvFileName!),
            ),
          ],
        ],
      ),
    );
  }
}
