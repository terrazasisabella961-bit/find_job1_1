import 'job_posting.dart';

class JobSuggestion {
  const JobSuggestion({
    required this.job,
    required this.score,
    required this.reasons,
  });

  final JobPosting job;
  final int score;
  final List<String> reasons;
}
