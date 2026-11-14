import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionCourse {
  const InstitutionCourse({
    required this.id,
    required this.ownerUid,
    required this.institutionName,
    required this.institutionLocation,
    required this.title,
    required this.programType,
    required this.studyArea,
    required this.modality,
    required this.duration,
    required this.description,
    required this.totalSeats,
    required this.minimumLevel,
    required this.requiredDocuments,
    required this.currency,
    required this.totalCost,
    required this.paymentPlan,
    required this.earlyDiscount,
    required this.includesCertification,
    required this.publicationDate,
    required this.applicationDeadline,
    required this.startDate,
    required this.whatsApp,
    required this.admissionsEmail,
    required this.brochureUrl,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String ownerUid;
  final String institutionName;
  final String institutionLocation;
  final String title;
  final String programType;
  final String studyArea;
  final String modality;
  final String duration;
  final String description;
  final int totalSeats;
  final String minimumLevel;
  final List<String> requiredDocuments;
  final String currency;
  final double totalCost;
  final String paymentPlan;
  final String earlyDiscount;
  final bool includesCertification;
  final DateTime publicationDate;
  final DateTime applicationDeadline;
  final DateTime startDate;
  final String whatsApp;
  final String admissionsEmail;
  final String? brochureUrl;
  final String status;
  final DateTime? createdAt;

  factory InstitutionCourse.fromMap(String id, Map<String, dynamic> data) {
    return InstitutionCourse(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      institutionName: data['institutionName'] as String? ?? '',
      institutionLocation: data['institutionLocation'] as String? ?? 'Bolivia',
      title: data['title'] as String? ?? '',
      programType: data['programType'] as String? ?? '',
      studyArea: data['studyArea'] as String? ?? '',
      modality: data['modality'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      description: data['description'] as String? ?? '',
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 0,
      minimumLevel: data['minimumLevel'] as String? ?? '',
      requiredDocuments: (data['requiredDocuments'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      currency: data['currency'] as String? ?? 'BOB',
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0,
      paymentPlan: data['paymentPlan'] as String? ?? '',
      earlyDiscount: data['earlyDiscount'] as String? ?? '',
      includesCertification: data['includesCertification'] as bool? ?? false,
      publicationDate: _date(data['publicationDate']) ?? DateTime.now(),
      applicationDeadline: _date(data['applicationDeadline']) ?? DateTime.now(),
      startDate: _date(data['startDate']) ?? DateTime.now(),
      whatsApp: data['whatsApp'] as String? ?? '',
      admissionsEmail: data['admissionsEmail'] as String? ?? '',
      brochureUrl: data['brochureUrl'] as String?,
      status: data['status'] as String? ?? 'draft',
      createdAt: _date(data['createdAt']),
    );
  }

  Map<String, Object?> toMap() => {
    'ownerUid': ownerUid,
    'institutionName': institutionName,
    'institutionLocation': institutionLocation,
    'title': title,
    'programType': programType,
    'studyArea': studyArea,
    'modality': modality,
    'duration': duration,
    'description': description,
    'totalSeats': totalSeats,
    'minimumLevel': minimumLevel,
    'requiredDocuments': requiredDocuments,
    'currency': currency,
    'totalCost': totalCost,
    'paymentPlan': paymentPlan,
    'earlyDiscount': earlyDiscount,
    'includesCertification': includesCertification,
    'publicationDate': Timestamp.fromDate(publicationDate),
    'applicationDeadline': Timestamp.fromDate(applicationDeadline),
    'startDate': Timestamp.fromDate(startDate),
    'whatsApp': whatsApp,
    'admissionsEmail': admissionsEmail,
    'brochureUrl': brochureUrl,
    'status': status,
  };

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
