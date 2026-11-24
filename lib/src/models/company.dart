class Company {
  const Company({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.taxId,
    required this.sector,
    required this.description,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    required this.website,
    this.logoUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String taxId;
  final String sector;
  final String description;
  final String email;
  final String phone;
  final String city;
  final String address;
  final String website;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory Company.fromMap(String id, Map<String, dynamic> data) => Company(
    id: id,
    ownerUid: data['ownerUid'] as String? ?? '',
    name: data['name'] as String? ?? '',
    taxId: data['taxId'] as String? ?? '',
    sector: data['sector'] as String? ?? '',
    description: data['description'] as String? ?? '',
    email: data['email'] as String? ?? '',
    phone: data['phone'] as String? ?? '',
    city: data['city'] as String? ?? '',
    address: data['address'] as String? ?? '',
    website: data['website'] as String? ?? '',
    logoUrl: data['logoUrl'] as String?,
    latitude: (data['latitude'] as num?)?.toDouble(),
    longitude: (data['longitude'] as num?)?.toDouble(),
  );

  Map<String, Object?> toMap() => {
    'ownerUid': ownerUid,
    'name': name,
    'taxId': taxId,
    'sector': sector,
    'description': description,
    'email': email,
    'phone': phone,
    'city': city,
    'address': address,
    'website': website,
    'logoUrl': logoUrl,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}
