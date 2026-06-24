import '../../core/utils/address_normalizer.dart';
import 'occupancy_status.dart';
import 'onboarding_checklist.dart';
import 'onboarding_status.dart';
import 'property_type.dart';

class Property {
  const Property({
    required this.id,
    required this.userId,
    required this.propertyAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    this.unitNumber,
    this.normalizedAddress,
    this.occupancyStatus,
    this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.onboardingStatus = OnboardingStatus.none,
    this.onboardingChecklist = const OnboardingChecklist(),
    this.createdAt,
  });

  final String id;
  final String userId;
  final String propertyAddress;
  final String city;
  final String state;
  final String zipCode;
  final String? unitNumber;
  final String? normalizedAddress;
  final OccupancyStatus? occupancyStatus;
  final PropertyType? propertyType;
  final int? bedrooms;
  final double? bathrooms;
  final OnboardingStatus onboardingStatus;
  final OnboardingChecklist onboardingChecklist;
  final DateTime? createdAt;

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      propertyAddress: json['property_address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zip_code'] as String? ?? '',
      unitNumber: json['unit_number'] as String?,
      normalizedAddress: json['normalized_address'] as String?,
      occupancyStatus: OccupancyStatus.fromJson(json['occupancy_status'] as String?),
      propertyType: PropertyType.fromJson(json['property_type'] as String?),
      bedrooms: json['bedrooms'] as int?,
      bathrooms: _parseDouble(json['bathrooms']),
      onboardingStatus: OnboardingStatus.fromJson(json['onboarding_status'] as String?),
      onboardingChecklist: OnboardingChecklist.fromJson(
        json['onboarding_checklist'] as Map<String, dynamic>?,
      ),
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
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'property_address': propertyAddress,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'unit_number': unitNumber,
      'normalized_address': AddressNormalizer.normalize(propertyAddress),
      if (propertyType != null) 'property_type': propertyType!.value,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      'onboarding_status': onboardingStatus.value,
      'onboarding_checklist': onboardingChecklist.toJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      ...toInsertJson(),
      if (occupancyStatus != null) 'occupancy_status': occupancyStatus!.value,
    };
  }

  String get displayAddress {
    final unit = unitNumber != null && unitNumber!.isNotEmpty
        ? 'Unit $unitNumber, '
        : '';
    return '$unit$propertyAddress, $city, $state $zipCode';
  }

  Property copyWith({
    String? propertyAddress,
    String? city,
    String? state,
    String? zipCode,
    String? unitNumber,
    OccupancyStatus? occupancyStatus,
    bool clearOccupancyStatus = false,
    PropertyType? propertyType,
    int? bedrooms,
    double? bathrooms,
    OnboardingStatus? onboardingStatus,
    OnboardingChecklist? onboardingChecklist,
  }) {
    return Property(
      id: id,
      userId: userId,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      unitNumber: unitNumber ?? this.unitNumber,
      normalizedAddress: normalizedAddress,
      occupancyStatus: clearOccupancyStatus ? null : (occupancyStatus ?? this.occupancyStatus),
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      onboardingChecklist: onboardingChecklist ?? this.onboardingChecklist,
      createdAt: createdAt,
    );
  }
}
