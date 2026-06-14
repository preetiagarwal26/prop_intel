import '../../core/utils/date_parser.dart';

class LeaseExtraction {
  const LeaseExtraction({
    this.propertyAddress = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.unitNumber = '',
    this.leaseStartDate,
    this.leaseEndDate,
    this.monthlyRent,
    this.securityDeposit,
    this.lateFee,
    this.tenantNames = const [],
    this.landlordName = '',
  });

  final String propertyAddress;
  final String city;
  final String state;
  final String zipCode;
  final String unitNumber;
  final String? leaseStartDate;
  final String? leaseEndDate;
  final String? monthlyRent;
  final String? securityDeposit;
  final String? lateFee;
  final List<String> tenantNames;
  final String landlordName;

  factory LeaseExtraction.fromJson(Map<String, dynamic> json) {
    final tenants = json['tenant_names'];
    return LeaseExtraction(
      propertyAddress: _stringValue(json['property_address']),
      city: _stringValue(json['city']),
      state: _stringValue(json['state']),
      zipCode: _stringValue(json['zip_code']),
      unitNumber: _stringValue(json['unit_number']),
      leaseStartDate: _nullableString(json['lease_start_date']),
      leaseEndDate: _nullableString(json['lease_end_date']),
      monthlyRent: _nullableString(json['monthly_rent']),
      securityDeposit: _nullableString(json['security_deposit']),
      lateFee: _nullableString(json['late_fee']),
      tenantNames: tenants is List
          ? tenants.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      landlordName: _stringValue(json['landlord_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'property_address': propertyAddress,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'unit_number': unitNumber,
      'lease_start_date': leaseStartDate,
      'lease_end_date': leaseEndDate,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'late_fee': lateFee,
      'tenant_names': tenantNames,
      'landlord_name': landlordName,
    };
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  double? get monthlyRentValue =>
      _parseMoney(monthlyRent);

  double? get securityDepositValue =>
      _parseMoney(securityDeposit);

  double? get lateFeeValue => _parseMoney(lateFee);

  static double? _parseMoney(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  DateTime? get leaseStartDateValue => DateParser.tryParse(leaseStartDate);

  DateTime? get leaseEndDateValue => DateParser.tryParse(leaseEndDate);

  LeaseExtraction copyWith({
    String? propertyAddress,
    String? city,
    String? state,
    String? zipCode,
    String? unitNumber,
    String? leaseStartDate,
    String? leaseEndDate,
    String? monthlyRent,
    String? securityDeposit,
    String? lateFee,
    List<String>? tenantNames,
    String? landlordName,
  }) {
    return LeaseExtraction(
      propertyAddress: propertyAddress ?? this.propertyAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      unitNumber: unitNumber ?? this.unitNumber,
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      leaseEndDate: leaseEndDate ?? this.leaseEndDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      lateFee: lateFee ?? this.lateFee,
      tenantNames: tenantNames ?? this.tenantNames,
      landlordName: landlordName ?? this.landlordName,
    );
  }
}
