class Lease {
  const Lease({
    required this.id,
    required this.propertyId,
    this.leaseStartDate,
    this.leaseEndDate,
    this.monthlyRent,
    this.securityDeposit,
    this.lateFee,
    this.tenantNames = const [],
    this.landlordName,
    this.rawExtractionJson,
    this.createdAt,
  });

  final String id;
  final String propertyId;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final double? monthlyRent;
  final double? securityDeposit;
  final double? lateFee;
  final List<String> tenantNames;
  final String? landlordName;
  final Map<String, dynamic>? rawExtractionJson;
  final DateTime? createdAt;

  factory Lease.fromJson(Map<String, dynamic> json) {
    final tenants = json['tenant_names'];
    return Lease(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      leaseStartDate: json['lease_start_date'] != null
          ? DateTime.parse(json['lease_start_date'] as String)
          : null,
      leaseEndDate: json['lease_end_date'] != null
          ? DateTime.parse(json['lease_end_date'] as String)
          : null,
      monthlyRent: _parseDouble(json['monthly_rent']),
      securityDeposit: _parseDouble(json['security_deposit']),
      lateFee: _parseDouble(json['late_fee']),
      tenantNames: tenants is List
          ? tenants.map((e) => e.toString()).toList()
          : const [],
      landlordName: json['landlord_name'] as String?,
      rawExtractionJson: json['raw_extraction_json'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'property_id': propertyId,
      'lease_start_date': leaseStartDate?.toIso8601String().split('T').first,
      'lease_end_date': leaseEndDate?.toIso8601String().split('T').first,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'late_fee': lateFee,
      'tenant_names': tenantNames,
      'landlord_name': landlordName,
      'raw_extraction_json': rawExtractionJson,
    };
  }
}
