import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/document_upload_draft.dart';
import '../../data/models/lease.dart';
import '../../data/models/property.dart';
import '../shared/document_intelligence_panel.dart';
import '../shared/document_metadata_fields.dart';
import '../shared/document_type_field.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.draft});

  final DocumentUploadDraft draft;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late DocumentUploadDraft _draft;
  bool _isSaving = false;
  String? _error;

  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _addressController = TextEditingController(text: _draft.propertyAddress);
    _cityController = TextEditingController(text: _draft.city);
    _stateController = TextEditingController(text: _draft.state);
    _zipController = TextEditingController(text: _draft.zipCode);
    _unitController = TextEditingController(text: _draft.unitNumber);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _syncDraftFromControllers() {
    _draft.propertyAddress = _addressController.text.trim();
    _draft.city = _cityController.text.trim();
    _draft.state = _stateController.text.trim();
    _draft.zipCode = _zipController.text.trim();
    _draft.unitNumber = _unitController.text.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _syncDraftFromControllers();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final repository = ref.read(supabaseRepositoryProvider);
    final classification = _draft.classification;

    try {
      final Property property;
      if (_draft.createNewProperty || _draft.matchedProperty == null) {
        property = await repository.createProperty(
          Property(
            id: '',
            userId: repository.currentUserId,
            propertyAddress: _draft.propertyAddress,
            city: _draft.city,
            state: _draft.state,
            zipCode: _draft.zipCode,
            unitNumber: _draft.unitNumber.isEmpty ? null : _draft.unitNumber,
          ),
        );
      } else {
        property = await repository.updateProperty(
          _draft.matchedProperty!.copyWith(
            propertyAddress: _draft.propertyAddress,
            city: _draft.city,
            state: _draft.state,
            zipCode: _draft.zipCode,
            unitNumber: _draft.unitNumber.isEmpty ? null : _draft.unitNumber,
          ),
        );
      }

      String? leaseId;
      if (_draft.isLease) {
        final extraction = _draft.toLeaseExtraction();
        final lease = await repository.createLease(
          Lease(
            id: '',
            propertyId: property.id,
            leaseStartDate: extraction.leaseStartDateValue,
            leaseEndDate: extraction.leaseEndDateValue,
            monthlyRent: extraction.monthlyRentValue,
            securityDeposit: extraction.securityDepositValue,
            lateFee: extraction.lateFeeValue,
            tenantNames: extraction.tenantNames,
            landlordName: extraction.landlordName.isEmpty ? null : extraction.landlordName,
            rawExtractionJson: extraction.toJson(),
          ),
        );
        leaseId = lease.id;
      }

      final savedDoc = await repository.updateDocument(
        documentId: _draft.documentId,
        propertyId: property.id,
        leaseId: leaseId,
        documentType: _draft.documentType,
        classificationConfidence: _draft.savedClassificationConfidence,
        extractedMetadata: _draft.extractedMetadata,
        summary: _draft.isManualClassification ? null : classification.summary,
        keyPoints: _draft.isManualClassification ? const [] : classification.keyPoints,
        flags: _draft.isManualClassification ? const [] : classification.flags,
      );

      final actionDrafts = ref.read(actionItemGeneratorServiceProvider).generate(
            property: property,
            document: savedDoc,
            documentType: _draft.documentType,
            metadata: _draft.extractedMetadata,
            flags: _draft.isManualClassification ? const [] : classification.flags,
          );
      await repository.replaceActionItemsForDocument(
        documentId: savedDoc.id,
        drafts: actionDrafts,
      );

      ref.invalidate(portfolioProvider);
      ref.invalidate(attentionProvider);
      ref.invalidate(propertyDetailProvider(property.id));
      ref.invalidate(
        documentDetailProvider(
          DocumentDetailKey(propertyId: property.id, documentId: savedDoc.id),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document saved successfully.')),
        );
        context.go('/property/${property.id}/document/${savedDoc.id}');
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to save document. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchLabel = _draft.createNewProperty
        ? 'New property'
        : 'Existing property (${(_draft.matchResult.confidence * 100).toStringAsFixed(0)}% match)';
    final classification = _draft.classification;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_draft.isManualClassification) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Document type was set manually. Confirm or change it below.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (classification.isLowConfidence) ...[
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low classification confidence. Please verify the document type.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            DocumentTypeField(
              value: _draft.documentType,
              enabled: !_isSaving,
              onChanged: (type) {
                if (type != null) {
                  setState(() => _draft.documentType = type);
                }
              },
            ),
            const SizedBox(height: 12),
            if (!_draft.isManualClassification)
              Chip(
                avatar: Icon(iconForDocumentType(_draft.documentType)),
                label: Text(
                  'AI confidence: '
                  '${(classification.confidence * 100).toStringAsFixed(0)}%',
                ),
              ),
            if (!_draft.isManualClassification) ...[
              const SizedBox(height: 16),
              DocumentIntelligencePanel(
                summary: classification.summary,
                keyPoints: classification.keyPoints,
                flags: classification.flags,
                compact: true,
              ),
            ],
            const SizedBox(height: 16),
            Chip(
              avatar: Icon(
                _draft.createNewProperty ? Icons.add_home : Icons.home,
              ),
              label: Text(matchLabel),
            ),
            const SizedBox(height: 16),
            Text('Property Info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _field(_addressController, 'Property address', required: true),
            _field(_cityController, 'City', required: true),
            _field(_stateController, 'State', required: true),
            _field(_zipController, 'ZIP code', required: true),
            _field(_unitController, 'Unit number'),
            SwitchListTile(
              title: const Text('Create as new property'),
              subtitle: const Text('Turn off to link to the matched property instead'),
              value: _draft.createNewProperty,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _draft.createNewProperty = value),
            ),
            const SizedBox(height: 24),
            Text('Document details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DocumentMetadataFields(
              documentType: _draft.documentType,
              metadata: _draft.extractedMetadata,
              enabled: !_isSaving,
              onChanged: (metadata) => setState(() => _draft.extractedMetadata = metadata),
            ),
            const SizedBox(height: 8),
            Text('File: ${_draft.fileName}'),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Document'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
