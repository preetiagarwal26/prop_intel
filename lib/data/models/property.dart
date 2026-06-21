import '../../core/utils/address_normalizer.dart';
import 'occupancy_status.dart';

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
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'property_address': propertyAddress,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'unit_number': unitNumber,
      'normalized_address': AddressNormalizer.normalize(propertyAddress),
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
      createdAt: createdAt,
    );
  }
}
