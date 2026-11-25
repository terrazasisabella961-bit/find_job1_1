import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/company.dart';
import '../models/job_posting.dart';
import '../services/job_application_repository.dart';
import '../services/recruitment_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import 'employment_screen.dart';

class CompanyPublicScreen extends StatelessWidget {
  const CompanyPublicScreen({
    required this.company,
    required this.repository,
    this.distanceLabel,
    this.applicationRepository,
    super.key,
  });

  final Company company;
  final RecruitmentRepository repository;
  final String? distanceLabel;
  final JobApplicationRepository? applicationRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<JobPosting>>(
          stream: repository.watchPublicJobs(),
          builder: (context, snapshot) {
            final jobs = (snapshot.data ?? const <JobPosting>[])
                .where(
                  (job) =>
                      job.companyId == company.id &&
                      job.status == 'published' &&
                      job.isCurrentlyListed(),
                )
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Volver',
                      icon: Icon(Icons.arrow_back, color: appTextColor),
                    ),
                    Expanded(
                      child: Text(
                        'EMPRESA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB48BF1),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  company.name,
                  style: TextStyle(
                    color: appTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  company.sector,
                  style: TextStyle(color: appPurpleColor, fontSize: 12),
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    distanceLabel!,
                    style: TextStyle(color: appOrangeColor, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'QUÉ ES ESTA EMPRESA',
                  style: TextStyle(
                    color: Color(0xFFB48BF1),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  company.description.trim().isEmpty
                      ? 'Esta empresa aún no publicó una descripción.'
                      : company.description,
                  style: TextStyle(
                    color: appTextColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(Icons.location_on_outlined, company.city),
                if (company.address.isNotEmpty)
                  _InfoRow(Icons.map_outlined, company.address),
                if (company.phone.isNotEmpty)
                  _InfoRow(Icons.call_outlined, company.phone),
                if (company.email.isNotEmpty)
                  _InfoRow(Icons.mail_outline, company.email),
                if (company.website.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      final uri = Uri.tryParse(company.website);
                      if (uri != null) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(Icons.language, size: 16),
                    label: Text(company.website),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  jobs.isEmpty
                      ? 'VACANTES'
                      : 'VACANTES (${jobs.length})',
                  style: TextStyle(
                    color: Color(0xFFB48BF1),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (jobs.isEmpty)
                  Text(
                    'No hay vacantes publicadas por ahora.',
                    style: TextStyle(color: appMutedColor, fontSize: 12),
                  )
                else
                  for (final job in jobs)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        job.title,
                        style: TextStyle(
                          color: appTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${job.modality} · ${job.employmentType}',
                        style: TextStyle(color: appMutedColor),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: appMutedColor,
                      ),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => JobDetailsScreen(
                            job: job,
                            applicationRepository: applicationRepository,
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: appMutedColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: appTextColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
