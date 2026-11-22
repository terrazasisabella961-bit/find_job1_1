import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.companyId,
    required this.applicantUid,
    required this.jobTitle,
    required this.companyName,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.areaOfInterest,
    required this.educationLevel,
    required this.careerTitle,
    required this.skills,
    required this.languages,
    required this.aboutMe,
    required this.message,
    required this.availability,
    required this.status,
    this.cvFileName,
    this.createdAt,
  });

  final String id;
  final String jobId;
  final String companyId;
  final String applicantUid;
  final String jobTitle;
  final String companyName;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final String areaOfInterest;
  final String educationLevel;
  final String careerTitle;
  final List<String> skills;
  final List<String> languages;
  final String aboutMe;
  final String message;
  final String availability;
  final String status;
  final String? cvFileName;
  final DateTime? createdAt;

  factory JobApplication.fromMap(String id, Map<String, dynamic> data) {
    return JobApplication(
      id: id,
      jobId: data['jobId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      applicantUid: data['applicantUid'] as String? ?? '',
      jobTitle: data['jobTitle'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? '',
      areaOfInterest: data['areaOfInterest'] as String? ?? '',
      educationLevel: data['educationLevel'] as String? ?? '',
      careerTitle: data['careerTitle'] as String? ?? '',
      skills: _strings(data['skills']),
      languages: _strings(data['languages']),
      aboutMe: data['aboutMe'] as String? ?? '',
      message: data['message'] as String? ?? '',
      availability: data['availability'] as String? ?? '',
      status: data['status'] as String? ?? 'received',
      cvFileName: data['cvFileName'] as String?,
      createdAt: _date(data['createdAt']),
    );
  }

  Map<String, Object?> toMap() => {
    'jobId': jobId,
    'companyId': companyId,
    'applicantUid': applicantUid,
    'jobTitle': jobTitle,
    'companyName': companyName,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'city': city,
    'areaOfInterest': areaOfInterest,
    'educationLevel': educationLevel,
    'careerTitle': careerTitle,
    'skills': skills,
    'languages': languages,
    'aboutMe': aboutMe,
    'message': message,
    'availability': availability,
    'status': status,
    'cvFileName': cvFileName,
  };

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
