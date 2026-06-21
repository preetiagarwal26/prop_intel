import 'document_classification.dart';
import 'document_type.dart';
import 'lease_extraction.dart';
import 'property.dart';

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

class DocumentUploadDraft {
  DocumentUploadDraft({
    required this.documentId,
    required this.storagePath,
    required this.fileName,
    required this.classification,
    required this.matchResult,
    String? propertyAddress,
    String? city,
    String? state,
    String? zipCode,
    String? unitNumber,
    DocumentType? documentType,
    bool? createNewProperty,
    Map<String, dynamic>? extractedMetadata,
    this.isManualClassification = false,
  })  : propertyAddress = propertyAddress ?? classification.propertyAddress,
        city = city ?? classification.city,
        state = state ?? classification.state,
        zipCode = zipCode ?? classification.zipCode,
        unitNumber = unitNumber ?? classification.unitNumber,
        documentType = documentType ?? classification.documentType,
        createNewProperty = createNewProperty ?? matchResult.isNewProperty,
        extractedMetadata = extractedMetadata ??
            Map<String, dynamic>.from(classification.extractedMetadata);

  final String documentId;
  final String storagePath;
  final String fileName;
  final DocumentClassification classification;
  final PropertyMatchResult matchResult;

  String propertyAddress;
  String city;
  String state;
  String zipCode;
  String unitNumber;
  DocumentType documentType;
  bool createNewProperty;
  Map<String, dynamic> extractedMetadata;
  final bool isManualClassification;

  Property? get matchedProperty => matchResult.property;

  bool get isLease => documentType == DocumentType.lease;

  double get savedClassificationConfidence =>
      isManualClassification ? 1.0 : classification.confidence;

  LeaseExtraction toLeaseExtraction() {
    final metadata = extractedMetadata;
    final tenants = metadata['tenant_names'];
    return LeaseExtraction(
      propertyAddress: propertyAddress,
      city: city,
      state: state,
      zipCode: zipCode,
      unitNumber: unitNumber,
      leaseStartDate: _nullableString(metadata['lease_start_date']),
      leaseEndDate: _nullableString(metadata['lease_end_date']),
      monthlyRent: _nullableString(metadata['monthly_rent']),
      securityDeposit: _nullableString(metadata['security_deposit']),
      lateFee: _nullableString(metadata['late_fee']),
      tenantNames: tenants is List
          ? tenants.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      landlordName: _stringValue(metadata['landlord_name']),
    );
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
}
