import 'document_flag.dart';
import 'document_type.dart';

class Document {
  const Document({
    required this.id,
    this.propertyId,
    this.leaseId,
    required this.fileName,
    required this.storagePath,
    this.uploadedAt,
    this.documentType,
    this.classificationConfidence,
    this.extractedMetadata = const {},
    this.summary,
    this.keyPoints = const [],
    this.flags = const [],
  });

  final String id;
  final String? propertyId;
  final String? leaseId;
  final String fileName;
  final String storagePath;
  final DateTime? uploadedAt;
  final DocumentType? documentType;
  final double? classificationConfidence;
  final Map<String, dynamic> extractedMetadata;
  final String? summary;
  final List<String> keyPoints;
  final List<DocumentFlag> flags;

  factory Document.fromJson(Map<String, dynamic> json) {
    final metadata = json['extracted_metadata'];
    final points = json['key_points'];
    final flagsJson = json['flags'];

    return Document(
      id: json['id'] as String,
      propertyId: json['property_id'] as String?,
      leaseId: json['lease_id'] as String?,
      fileName: json['file_name'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
      documentType: json['document_type'] != null
          ? DocumentType.fromValue(json['document_type'] as String?)
          : null,
      classificationConfidence:
          (json['classification_confidence'] as num?)?.toDouble(),
      extractedMetadata: metadata is Map<String, dynamic>
          ? Map<String, dynamic>.from(metadata)
          : const {},
      summary: json['summary'] as String?,
      keyPoints: points is List
          ? points.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      flags: flagsJson is List
          ? flagsJson
              .whereType<Map<String, dynamic>>()
              .map(DocumentFlag.fromJson)
              .toList()
          : const [],
    );
  }
}
