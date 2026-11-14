class Institution {
  const Institution({
    required this.uid,
    required this.legalName,
    required this.displayName,
    required this.type,
    required this.taxId,
    required this.accreditation,
    required this.country,
    required this.city,
    required this.address,
    required this.website,
    required this.primaryDomain,
    required this.secondaryDomains,
    required this.representativeName,
    required this.representativeRole,
    required this.phone,
    required this.contactEmail,
    required this.adminEmail,
    required this.verificationStatus,
    required this.twoFactorRequested,
    this.createdAt,
  });

  final String uid;
  final String legalName;
  final String displayName;
  final String type;
  final String taxId;
  final String accreditation;
  final String country;
  final String city;
  final String address;
  final String website;
  final String primaryDomain;
  final List<String> secondaryDomains;
  final String representativeName;
  final String representativeRole;
  final String phone;
  final String contactEmail;
  final String adminEmail;
  final String verificationStatus;
  final bool twoFactorRequested;
  final DateTime? createdAt;

  bool get isVerified => verificationStatus == 'verified';

  factory Institution.fromMap(String uid, Map<String, dynamic> data) {
    return Institution(
      uid: uid,
      legalName: data['legalName'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      type: data['type'] as String? ?? '',
      taxId: data['taxId'] as String? ?? '',
      accreditation: data['accreditation'] as String? ?? '',
      country: data['country'] as String? ?? '',
      city: data['city'] as String? ?? '',
      address: data['address'] as String? ?? '',
      website: data['website'] as String? ?? '',
      primaryDomain: data['primaryDomain'] as String? ?? '',
      secondaryDomains: (data['secondaryDomains'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      representativeName: data['representativeName'] as String? ?? '',
      representativeRole: data['representativeRole'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      contactEmail: data['contactEmail'] as String? ?? '',
      adminEmail: data['adminEmail'] as String? ?? '',
      verificationStatus: data['verificationStatus'] as String? ?? 'pending',
      twoFactorRequested: data['twoFactorRequested'] as bool? ?? false,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, Object?> toMap() => {
    'ownerUid': uid,
    'legalName': legalName,
    'displayName': displayName,
    'type': type,
    'taxId': taxId,
    'accreditation': accreditation,
    'country': country,
    'city': city,
    'address': address,
    'website': website,
    'primaryDomain': primaryDomain,
    'secondaryDomains': secondaryDomains,
    'representativeName': representativeName,
    'representativeRole': representativeRole,
    'phone': phone,
    'contactEmail': contactEmail,
    'adminEmail': adminEmail,
    'verificationStatus': verificationStatus,
    'twoFactorRequested': twoFactorRequested,
  };

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
