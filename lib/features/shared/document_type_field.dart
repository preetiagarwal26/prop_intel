import 'package:flutter/material.dart';

import '../../data/models/document_type.dart';

class DocumentTypeField extends StatelessWidget {
  const DocumentTypeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Document type',
  });

  final DocumentType value;
  final ValueChanged<DocumentType?> onChanged;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DocumentType>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: DocumentType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type.label),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

IconData iconForDocumentType(DocumentType type) {
  return switch (type) {
    DocumentType.lease => Icons.description,
    DocumentType.deed => Icons.gavel,
    DocumentType.insurance => Icons.shield,
    DocumentType.utility => Icons.bolt,
    DocumentType.tax => Icons.receipt_long,
    DocumentType.hoa => Icons.apartment,
    DocumentType.permit => Icons.verified,
    DocumentType.other => Icons.insert_drive_file,
  };
}
