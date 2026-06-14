class Document {
  const Document({
    required this.id,
    this.propertyId,
    this.leaseId,
    required this.fileName,
    required this.storagePath,
    this.uploadedAt,
  });

  final String id;
  final String? propertyId;
  final String? leaseId;
  final String fileName;
  final String storagePath;
  final DateTime? uploadedAt;

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      propertyId: json['property_id'] as String?,
      leaseId: json['lease_id'] as String?,
      fileName: json['file_name'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson({
    required String propertyId,
    String? leaseId,
  }) {
    return {
      'property_id': propertyId,
      'lease_id': leaseId,
      'file_name': fileName,
      'storage_path': storagePath,
    };
  }
}
