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

  bool get hasCoordinates => latitude != null && longitude != null;

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
    );
  }
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
