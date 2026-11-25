const profileEducationLevels = [
  'Bachillerato',
  'Técnico',
  'Licenciatura',
  'Maestría',
];

const profileSkillTags = [
  'Comunicación',
  'Trabajo en equipo',
  'Atención al cliente',
  'Ventas',
  'Ofimática',
  'Informática',
  'Liderazgo',
  'Logística',
  'Docencia',
  'Contabilidad',
];

const profileLanguageNames = [
  'Español',
  'Quechua',
  'Inglés',
  'Aymara',
  'Portugués',
];

const profileLanguageLevels = [
  'Básico',
  'Intermedio',
  'Avanzado',
  'Nativo',
];

class ProfileLanguage {
  const ProfileLanguage({
    required this.name,
    this.level = 'Intermedio',
  });

  final String name;
  final String level;

  Map<String, Object?> toMap() => {
    'name': name,
    'level': level,
  };

  factory ProfileLanguage.fromMap(Map<String, dynamic> data) {
    final level = data['level'] as String? ?? 'Intermedio';
    return ProfileLanguage(
      name: data['name'] as String? ?? '',
      level: profileLanguageLevels.contains(level) ? level : 'Intermedio',
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.areaOfInterest,
    this.educationLevel = '',
    this.careerTitle = '',
    this.skills = const [],
    this.languages = const [],
    this.aboutMe = '',
    this.acceptedTerms = false,
    this.isVisible = false,
    this.cvUrl,
    this.cvFileName,
    this.latitude,
    this.longitude,
    this.birthDate,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String areaOfInterest;
  final String educationLevel;
  final String careerTitle;
  final List<String> skills;
  final List<ProfileLanguage> languages;
  final String aboutMe;
  final bool acceptedTerms;
  final bool isVisible;
  final String? cvUrl;
  final String? cvFileName;
  final double? latitude;
  final double? longitude;
  final DateTime? birthDate;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isUnder18 =>
      birthDate != null && !isAtLeast18YearsOld(birthDate!);

  Map<String, Object?> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'city': city,
    'areaOfInterest': areaOfInterest,
    'educationLevel': educationLevel,
    'careerTitle': careerTitle,
    'skills': skills,
    'languages': languages.map((language) => language.toMap()).toList(),
    'aboutMe': aboutMe,
    'acceptedTerms': acceptedTerms,
    'isVisible': isVisible,
    'cvUrl': cvUrl,
    'cvFileName': cvFileName,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (birthDate != null) 'birthDate': formatBirthDateIso(birthDate!),
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? '',
      areaOfInterest: data['areaOfInterest'] as String? ?? '',
      educationLevel: data['educationLevel'] as String? ?? '',
      careerTitle: data['careerTitle'] as String? ?? '',
      skills: _stringList(data['skills']),
      languages: _languageList(data['languages']),
      aboutMe: data['aboutMe'] as String? ?? '',
      acceptedTerms: data['acceptedTerms'] as bool? ?? false,
      isVisible: data['isVisible'] as bool? ?? false,
      cvUrl: data['cvUrl'] as String?,
      cvFileName: data['cvFileName'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      birthDate: parseBirthDate(data['birthDate']),
    );
  }
}

DateTime latestAdultBirthDate([DateTime? now]) {
  final today = now ?? DateTime.now();
  return DateTime(today.year - 18, today.month, today.day);
}

bool isAtLeast18YearsOld(DateTime birthDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
  var age = today.year - birth.year;
  if (today.month < birth.month ||
      (today.month == birth.month && today.day < birth.day)) {
    age--;
  }
  return age >= 18;
}

String formatBirthDateIso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String formatBirthDateDisplay(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

DateTime? parseBirthDate(Object? value) {
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  if (value is! String || value.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<ProfileLanguage> _languageList(Object? value) {
  if (value is! List) return const [];
  final languages = <ProfileLanguage>[];
  for (final item in value) {
    if (item is Map) {
      final language = ProfileLanguage.fromMap(
        Map<String, dynamic>.from(item),
      );
      if (language.name.isNotEmpty) languages.add(language);
    }
  }
  return languages;
}
