import '../models/lease_extraction.dart';
import '../models/property.dart';

enum PropertyMatchType { exact, location, fuzzy, none }

class PropertyMatchResult {
  const PropertyMatchResult({
    this.property,
    required this.confidence,
    required this.matchType,
    required this.isNewProperty,
  });

  final Property? property;
  final double confidence;
  final PropertyMatchType matchType;
  final bool isNewProperty;

  factory PropertyMatchResult.noMatch() {
    return const PropertyMatchResult(
      confidence: 0,
      matchType: PropertyMatchType.none,
      isNewProperty: true,
    );
  }
}

class LeaseUploadDraft {
  LeaseUploadDraft({
    required this.documentId,
    required this.storagePath,
    required this.fileName,
    required this.extraction,
    required this.matchResult,
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
    bool? createNewProperty,
  })  : propertyAddress = propertyAddress ?? extraction.propertyAddress,
        city = city ?? extraction.city,
        state = state ?? extraction.state,
        zipCode = zipCode ?? extraction.zipCode,
        unitNumber = unitNumber ?? extraction.unitNumber,
        leaseStartDate = leaseStartDate ?? extraction.leaseStartDate ?? '',
        leaseEndDate = leaseEndDate ?? extraction.leaseEndDate ?? '',
        monthlyRent = monthlyRent ?? extraction.monthlyRent ?? '',
        securityDeposit = securityDeposit ?? extraction.securityDeposit ?? '',
        lateFee = lateFee ?? extraction.lateFee ?? '',
        tenantNames = tenantNames ?? List<String>.from(extraction.tenantNames),
        landlordName = landlordName ?? extraction.landlordName,
        createNewProperty = createNewProperty ?? matchResult.isNewProperty;

  final String documentId;
  final String storagePath;
  final String fileName;
  final LeaseExtraction extraction;
  final PropertyMatchResult matchResult;

  String propertyAddress;
  String city;
  String state;
  String zipCode;
  String unitNumber;
  String leaseStartDate;
  String leaseEndDate;
  String monthlyRent;
  String securityDeposit;
  String lateFee;
  List<String> tenantNames;
  String landlordName;
  bool createNewProperty;

  Property? get matchedProperty => matchResult.property;

  LeaseExtraction toExtraction() {
    return LeaseExtraction(
      propertyAddress: propertyAddress,
      city: city,
      state: state,
      zipCode: zipCode,
      unitNumber: unitNumber,
      leaseStartDate: leaseStartDate.isEmpty ? null : leaseStartDate,
      leaseEndDate: leaseEndDate.isEmpty ? null : leaseEndDate,
      monthlyRent: monthlyRent.isEmpty ? null : monthlyRent,
      securityDeposit: securityDeposit.isEmpty ? null : securityDeposit,
      lateFee: lateFee.isEmpty ? null : lateFee,
      tenantNames: tenantNames,
      landlordName: landlordName,
    );
  }
}
