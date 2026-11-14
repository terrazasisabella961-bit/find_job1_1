import 'package:cloud_firestore/cloud_firestore.dart';

class JobPosting {
  const JobPosting({
    required this.id,
    required this.companyId,
    required this.ownerUid,
    required this.companyName,
    required this.companySector,
    required this.companyEmail,
    required this.companyPhone,
    required this.companyWebsite,
    required this.companyAddress,
    required this.title,
    required this.description,
    required this.responsibilities,
    required this.requirements,
    required this.area,
    required this.city,
    required this.modality,
    required this.employmentType,
    required this.experience,
    required this.education,
    required this.salaryMinimum,
    required this.salaryMaximum,
    required this.currency,
    required this.createdAt,
    required this.deadline,
    required this.status,
    this.zone = '',
    this.requiredDocuments = const [],
    this.skills = const [],
    this.salaryConfidential = false,
    this.benefits = const [],
    DateTime? publicationDate,
    this.vacancyCount = 1,
    this.applicationChannel = 'app',
    this.contactEmail = '',
    this.whatsApp = '',
  }) : publicationDate = publicationDate ?? createdAt;

  final String id;
  final String companyId;
  final String ownerUid;
  final String companyName;
  final String companySector;
  final String companyEmail;
  final String companyPhone;
  final String companyWebsite;
  final String companyAddress;
  final String title;
  final String description;
  final String responsibilities;
  final String requirements;
  final String area;
  final String city;
  final String modality;
  final String employmentType;
  final String experience;
  final String education;
  final int? salaryMinimum;
  final int? salaryMaximum;
  final String currency;
  final DateTime createdAt;
  final DateTime? deadline;
  final String status;
  final String zone;
  final List<String> requiredDocuments;
  final List<String> skills;
  final bool salaryConfidential;
  final List<String> benefits;
  final DateTime publicationDate;
  final int vacancyCount;
  final String applicationChannel;
  final String contactEmail;
  final String whatsApp;

  bool get hasSalary => salaryMinimum != null || salaryMaximum != null;

  factory JobPosting.fromMap(String id, Map<String, dynamic> data) {
    return JobPosting(
      id: id,
      companyId: data['companyId'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      companySector: data['companySector'] as String? ?? '',
      companyEmail: data['companyEmail'] as String? ?? '',
      companyPhone: data['companyPhone'] as String? ?? '',
      companyWebsite: data['companyWebsite'] as String? ?? '',
      companyAddress: data['companyAddress'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      responsibilities: data['responsibilities'] as String? ?? '',
      requirements: data['requirements'] as String? ?? '',
      area: data['area'] as String? ?? '',
      city: data['city'] as String? ?? '',
      modality: data['modality'] as String? ?? '',
      employmentType: data['employmentType'] as String? ?? '',
      experience: data['experience'] as String? ?? '',
      education: data['education'] as String? ?? '',
      salaryMinimum: (data['salaryMinimum'] as num?)?.toInt(),
      salaryMaximum: (data['salaryMaximum'] as num?)?.toInt(),
      currency: data['currency'] as String? ?? 'BOB',
      createdAt: _dateTime(data['createdAt']) ?? DateTime.now(),
      deadline: _dateTime(data['deadline']),
      status: data['status'] as String? ?? 'paused',
      zone: data['zone'] as String? ?? '',
      requiredDocuments: _stringList(data['requiredDocuments']),
      skills: _stringList(data['skills']),
      salaryConfidential: data['salaryConfidential'] as bool? ?? false,
      benefits: _stringList(data['benefits']),
      publicationDate:
          _dateTime(data['publicationDate']) ??
          _dateTime(data['createdAt']) ??
          DateTime.now(),
      vacancyCount: (data['vacancyCount'] as num?)?.toInt() ?? 1,
      applicationChannel: data['applicationChannel'] as String? ?? 'app',
      contactEmail: data['contactEmail'] as String? ?? '',
      whatsApp: data['whatsApp'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => {
    'companyId': companyId,
    'ownerUid': ownerUid,
    'companyName': companyName,
    'companySector': companySector,
    'companyEmail': companyEmail,
    'companyPhone': companyPhone,
    'companyWebsite': companyWebsite,
    'companyAddress': companyAddress,
    'title': title,
    'description': description,
    'responsibilities': responsibilities,
    'requirements': requirements,
    'area': area,
    'city': city,
    'modality': modality,
    'employmentType': employmentType,
    'experience': experience,
    'education': education,
    'salaryMinimum': salaryMinimum,
    'salaryMaximum': salaryMaximum,
    'currency': currency,
    'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
    'status': status,
    'zone': zone,
    'requiredDocuments': requiredDocuments,
    'skills': skills,
    'salaryConfidential': salaryConfidential,
    'benefits': benefits,
    'publicationDate': Timestamp.fromDate(publicationDate),
    'vacancyCount': vacancyCount,
    'applicationChannel': applicationChannel,
    'contactEmail': contactEmail,
    'whatsApp': whatsApp,
  };

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String> _stringList(Object? value) =>
      (value as List<dynamic>? ?? const []).whereType<String>().toList();
}
