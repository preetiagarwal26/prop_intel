import 'document_type.dart';

class PropertyAddressHint {
  const PropertyAddressHint({
    this.propertyAddress = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.unitNumber = '',
  });

  final String propertyAddress;
  final String city;
  final String state;
  final String zipCode;
  final String unitNumber;
}

class DocumentClassification {
  const DocumentClassification({
    required this.documentType,
    required this.confidence,
    this.propertyAddress = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.unitNumber = '',
    this.summary = '',
    this.extractedMetadata = const {},
  });

  final DocumentType documentType;
  final double confidence;
  final String propertyAddress;
  final String city;
  final String state;
  final String zipCode;
  final String unitNumber;
  final String summary;
  final Map<String, dynamic> extractedMetadata;

  PropertyAddressHint get addressHint => PropertyAddressHint(
        propertyAddress: propertyAddress,
        city: city,
        state: state,
        zipCode: zipCode,
        unitNumber: unitNumber,
      );

  factory DocumentClassification.fromJson(Map<String, dynamic> json) {
    final metadata = json['extracted_metadata'];
    return DocumentClassification(
      documentType: DocumentType.fromValue(json['document_type'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      propertyAddress: _stringValue(json['property_address']),
      city: _stringValue(json['city']),
      state: _stringValue(json['state']),
      zipCode: _stringValue(json['zip_code']),
      unitNumber: _stringValue(json['unit_number']),
      summary: _stringValue(json['summary']),
      extractedMetadata: metadata is Map<String, dynamic>
          ? Map<String, dynamic>.from(metadata)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_type': documentType.value,
      'confidence': confidence,
      'property_address': propertyAddress,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'unit_number': unitNumber,
      'summary': summary,
      'extracted_metadata': extractedMetadata,
    };
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  /// Used when automatic classification fails or is skipped.
  factory DocumentClassification.manual({
    DocumentType documentType = DocumentType.other,
  }) {
    return DocumentClassification(
      documentType: documentType,
      confidence: 0,
      summary: 'Document type selected manually.',
    );
  }

  bool get isLowConfidence => confidence > 0 && confidence < 0.6;
}
