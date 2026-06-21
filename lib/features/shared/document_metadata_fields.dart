import 'package:flutter/material.dart';

import '../../data/models/document_type.dart';
import 'document_metadata_helpers.dart';

class DocumentMetadataFields extends StatefulWidget {
  const DocumentMetadataFields({
    super.key,
    required this.documentType,
    required this.metadata,
    required this.onChanged,
    this.enabled = true,
  });

  final DocumentType documentType;
  final Map<String, dynamic> metadata;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool enabled;

  @override
  State<DocumentMetadataFields> createState() => _DocumentMetadataFieldsState();
}

class _DocumentMetadataFieldsState extends State<DocumentMetadataFields> {
  late Map<String, TextEditingController> _controllers;
  DocumentType? _lastType;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(DocumentMetadataFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentType != widget.documentType) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    _lastType = widget.documentType;
    _controllers = {};
    for (final entry in metadataFieldsForType(widget.documentType).entries) {
      _controllers[entry.key] = TextEditingController(
        text: metadataValueAsString(widget.metadata[entry.key]),
      );
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers = {};
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _syncMetadata() {
    final updated = Map<String, dynamic>.from(widget.metadata);
    for (final entry in _controllers.entries) {
      final value = metadataValueFromString(entry.key, entry.value.text);
      if (value == null) {
        updated.remove(entry.key);
      } else {
        updated[entry.key] = value;
      }
    }
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_lastType != widget.documentType) {
      _disposeControllers();
      _initControllers();
    }

    final fields = metadataFieldsForType(widget.documentType);

    return Column(
      children: fields.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _controllers[entry.key],
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: entry.value,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _syncMetadata(),
          ),
        );
      }).toList(),
    );
  }
}
