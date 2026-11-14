class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.areaOfInterest,
    this.acceptedTerms = false,
    this.isVisible = false,
    this.cvUrl,
    this.cvFileName,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String areaOfInterest;
  final bool acceptedTerms;
  final bool isVisible;
  final String? cvUrl;
  final String? cvFileName;

  Map<String, Object?> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'city': city,
    'areaOfInterest': areaOfInterest,
    'acceptedTerms': acceptedTerms,
    'isVisible': isVisible,
    'cvUrl': cvUrl,
    'cvFileName': cvFileName,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, Object?> data) {
    return UserProfile(
      uid: data['uid'] as String,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? '',
      areaOfInterest: data['areaOfInterest'] as String? ?? '',
      acceptedTerms: data['acceptedTerms'] as bool? ?? false,
      isVisible: data['isVisible'] as bool? ?? false,
      cvUrl: data['cvUrl'] as String?,
      cvFileName: data['cvFileName'] as String?,
    );
  }
}
