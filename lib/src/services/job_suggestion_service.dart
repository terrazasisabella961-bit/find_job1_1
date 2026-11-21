import '../models/job_posting.dart';
import '../models/job_suggestion.dart';
import '../models/user_profile.dart';

/// Optional LLM rerank. The default path never calls this.
abstract interface class JobSuggestionReranker {
  Future<List<JobSuggestion>> rerank({
    required UserProfile profile,
    required List<JobSuggestion> suggestions,
  });
}

abstract interface class JobSuggestionService {
  List<JobSuggestion> suggest({
    UserProfile? profile,
    required List<JobPosting> jobs,
    DateTime? now,
    int limit = 8,
  });
}

class LocalJobSuggestionService implements JobSuggestionService {
  const LocalJobSuggestionService({
    this.reranker,
    this.minimumScore = 35,
  });

  /// Kept injectable and unused unless a caller opts in later.
  final JobSuggestionReranker? reranker;
  final int minimumScore;

  static const _areaWeight = 40;
  static const _cityWeight = 35;
  static const _remoteCityWeight = 20;
  static const _tokenWeight = 25;

  @override
  List<JobSuggestion> suggest({
    UserProfile? profile,
    required List<JobPosting> jobs,
    DateTime? now,
    int limit = 8,
  }) {
    if (profile == null) return const [];
    final city = profile.city.trim();
    final area = profile.areaOfInterest.trim();
    if (city.isEmpty && area.isEmpty) return const [];

    final ranked = <JobSuggestion>[];
    for (final job in jobs) {
      if (job.status != 'published' || !job.isCurrentlyListed(now)) {
        continue;
      }
      final suggestion = _score(profile, job);
      if (suggestion != null && suggestion.score >= minimumScore) {
        ranked.add(suggestion);
      }
    }
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.job.createdAt.compareTo(a.job.createdAt);
    });
    if (ranked.length <= limit) return ranked;
    return ranked.sublist(0, limit);
  }

  JobSuggestion? _score(UserProfile profile, JobPosting job) {
    var score = 0;
    final reasons = <String>[];
    final profileArea = _fold(profile.areaOfInterest);
    final profileCity = _fold(profile.city);
    final jobArea = _fold(job.area);
    final jobCity = _fold(job.city);
    final jobTitle = _fold(job.title);
    final jobSector = _fold(job.companySector);
    final haystack = _fold(
      [
        job.title,
        job.area,
        job.companySector,
        job.requirements,
        job.skills.join(' '),
        job.description,
      ].join(' '),
    );

    if (profileArea.isNotEmpty) {
      if (jobArea == profileArea ||
          (jobArea.isNotEmpty &&
              (jobArea.contains(profileArea) ||
                  profileArea.contains(jobArea)))) {
        score += _areaWeight;
        reasons.add('Coincide tu área ${profile.areaOfInterest.trim()}');
      } else if (jobTitle.contains(profileArea) ||
          jobSector.contains(profileArea)) {
        score += 28;
        reasons.add('Tu área aparece en ${job.title}');
      }
    }

    if (profileCity.isNotEmpty && jobCity == profileCity) {
      score += _cityWeight;
      reasons.add('Misma ciudad: ${profile.city.trim()}');
    } else if (job.isRemote) {
      score += _remoteCityWeight;
      reasons.add('Modalidad remota, no exige tu ciudad');
    }

    final tokens = _tokens(profile.areaOfInterest);
    if (tokens.isNotEmpty) {
      var tokenHits = 0;
      for (final token in tokens) {
        if (haystack.contains(token)) tokenHits += 1;
      }
      if (tokenHits > 0) {
        final tokenScore = (tokenHits * 8).clamp(0, _tokenWeight);
        score += tokenScore;
        if (reasons.length < 3 &&
            !reasons.any((reason) => reason.contains('área'))) {
          reasons.add('Encaja con tu área de interés');
        }
      }
    }

    if (score <= 0 || reasons.isEmpty) return null;
    return JobSuggestion(
      job: job,
      score: score.clamp(0, 100),
      reasons: reasons.take(3).toList(),
    );
  }

  static String _fold(String value) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñç';
    const to = 'aaaaeeeeiiiioooouuuunc';
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }

  static Set<String> _tokens(String value) {
    return _fold(value)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 4)
        .toSet();
  }
}
