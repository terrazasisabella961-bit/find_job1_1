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
    this.minimumScore = 40,
  });

  /// Kept injectable and unused unless a caller opts in later.
  final JobSuggestionReranker? reranker;
  final int minimumScore;

  static const _areaWeight = 48;
  static const _relatedAreaWeight = 42;
  static const _cityWeight = 18;
  static const _remoteCityWeight = 10;
  static const _tokenWeight = 24;

  static const _areaFamilies = <Set<String>>[
    {
      'tecnologia',
      'software',
      'informatica',
      'sistemas',
      'programacion',
      'datos',
      'backend',
      'frontend',
      'fullstack',
      'ciberseguridad',
      'python',
      'react',
      'node',
    },
    {
      'ambiental',
      'ambiente',
      'sostenible',
      'residuos',
      'ecologia',
      'impacto',
    },
    {
      'marketing',
      'publicidad',
      'comunicacion',
      'community',
      'redes',
      'contenido',
    },
    {
      'diseno',
      'diseño',
      'ux',
      'ui',
      'figma',
      'prototipado',
      'grafico',
    },
    {
      'administracion',
      'negocios',
      'finanzas',
      'recursos',
      'humano',
      'seleccion',
      'rrhh',
    },
    {
      'ingenieria',
      'industrial',
      'civil',
      'obras',
    },
    {
      'salud',
      'medicina',
      'enfermeria',
    },
    {
      'educacion',
      'docencia',
      'pedagogia',
    },
    {
      'ventas',
      'comercio',
      'cliente',
    },
    {
      'gastronomia',
      'cocina',
      'alimentos',
    },
  ];

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
    final career = profile.careerTitle.trim();
    if (city.isEmpty &&
        area.isEmpty &&
        career.isEmpty &&
        profile.skills.isEmpty) {
      return const [];
    }

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
    final profileFocus = _fold(
      [
        profile.areaOfInterest,
        profile.careerTitle,
        ...profile.skills,
      ].join(' '),
    );

    final areaMatched = _directAreaMatch(profileArea, jobArea, haystack);
    final familyMatched =
        profileFocus.isNotEmpty && _shareAreaFamily(profileFocus, haystack);

    if (areaMatched) {
      score += _areaWeight;
      reasons.add('Coincide tu área ${profile.areaOfInterest.trim()}');
    } else if (familyMatched) {
      score += _relatedAreaWeight;
      reasons.add(
        profile.areaOfInterest.trim().isEmpty
            ? 'Relacionada con tu perfil profesional'
            : 'Relacionada con tu área ${profile.areaOfInterest.trim()}',
      );
    }

    var skillHits = 0;
    if (profile.skills.isNotEmpty) {
      for (final skill in profile.skills) {
        final folded = _fold(skill);
        if (folded.length < 3) continue;
        if (haystack.contains(folded)) skillHits += 1;
      }
      if (skillHits > 0) {
        score += (skillHits * 8).clamp(0, 20);
        reasons.add(
          skillHits == 1
              ? 'Coincide una habilidad de tu perfil'
              : 'Coinciden $skillHits habilidades',
        );
      }
    }

    final tokens = {
      ..._tokens(profile.areaOfInterest),
      ..._tokens(profile.careerTitle),
    };
    var tokenHits = 0;
    if (tokens.isNotEmpty) {
      for (final token in tokens) {
        if (_haystackHasToken(haystack, token)) tokenHits += 1;
      }
      if (tokenHits > 0) {
        score += (tokenHits * 8).clamp(0, _tokenWeight);
        if (!reasons.any((reason) => reason.toLowerCase().contains('área'))) {
          reasons.add('Encaja con tu formación o área de interés');
        }
      }
    }

    final hasProfessionalMatch =
        areaMatched || familyMatched || skillHits > 0 || tokenHits > 0;
    if (!hasProfessionalMatch) return null;

    if (profileCity.isNotEmpty && jobCity == profileCity) {
      score += _cityWeight;
      reasons.add('Misma ciudad: ${profile.city.trim()}');
    } else if (job.isRemote && (areaMatched || familyMatched)) {
      score += _remoteCityWeight;
      reasons.add('Modalidad remota, no exige tu ciudad');
    }

    final education = _fold(profile.educationLevel);
    if (education.isNotEmpty) {
      final jobEducation = _fold(job.education);
      if (jobEducation.contains(education) ||
          (jobEducation.isNotEmpty && education.contains(jobEducation))) {
        score += 6;
      }
    }

    if (score < minimumScore || reasons.isEmpty) return null;
    return JobSuggestion(
      job: job,
      score: score.clamp(0, 100),
      reasons: reasons.take(3).toList(),
    );
  }

  static bool _directAreaMatch(
    String profileArea,
    String jobArea,
    String haystack,
  ) {
    if (profileArea.isEmpty) return false;
    if (jobArea.isNotEmpty &&
        (jobArea == profileArea ||
            jobArea.contains(profileArea) ||
            profileArea.contains(jobArea))) {
      return true;
    }
    return haystack.contains(profileArea);
  }

  static bool _shareAreaFamily(String profileFocus, String jobFocus) {
    for (final family in _areaFamilies) {
      final inProfile = family.any(profileFocus.contains);
      final inJob = family.any(jobFocus.contains);
      if (inProfile && inJob) return true;
    }
    return false;
  }

  static bool _haystackHasToken(String haystack, String token) {
    if (haystack.contains(token)) return true;
    if (token.length >= 6) {
      final stem = token.substring(0, token.length - 1);
      return haystack.contains(stem);
    }
    return false;
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
