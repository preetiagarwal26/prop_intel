import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/document_classification.dart';
import '../../data/models/document_type.dart';
import '../../data/models/document_upload_draft.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/property_matching_service.dart';
import '../shared/app_shell.dart';
import '../shared/document_type_field.dart';
import '../shared/prop_vault_card.dart';

enum UploadStep {
  idle,
  uploading,
  extracting,
  classifying,
  matching,
  manualClassify,
  done,
  error,
}

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key, this.onboardingMode = false});

  /// When true, guides the user to start with a settlement statement.
  final bool onboardingMode;

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  UploadStep _step = UploadStep.idle;
  String? _error;
  String? _statusMessage;
  PlatformFile? _selectedFile;

  String? _documentId;
  String? _storagePath;
  late DocumentType _manualType;

  @override
  void initState() {
    super.initState();
    _manualType =
        widget.onboardingMode ? DocumentType.settlement : DocumentType.other;
  }

  Future<void> _pickAndProcess() async {
    setState(() {
      _error = null;
      _statusMessage = null;
      _step = UploadStep.idle;
      _documentId = null;
      _storagePath = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() {
        _error = 'Could not read the selected file.';
        _step = UploadStep.error;
      });
      return;
    }

    _selectedFile = file;
    await _processFile(file);
  }

  Future<void> _processFile(PlatformFile file) async {
    final storageService = ref.read(documentStorageServiceProvider);
    final pdfService = ref.read(pdfExtractionServiceProvider);
    final classificationService = ref.read(documentClassificationServiceProvider);
    final matchingService = ref.read(propertyMatchingServiceProvider);
    final repository = ref.read(supabaseRepositoryProvider);

    try {
      setState(() {
        _step = UploadStep.uploading;
        _statusMessage = 'Uploading document...';
        _error = null;
      });

      final uploadResult = await storageService.uploadDocument(
        fileName: file.name,
        bytes: file.bytes!,
      );

      _documentId = uploadResult.document.id;
      _storagePath = uploadResult.storagePath;

      setState(() {
        _step = UploadStep.extracting;
        _statusMessage = 'Extracting text from PDF...';
      });

      final documentText = await pdfService.extractText(file.bytes!);

      setState(() {
        _step = UploadStep.classifying;
        _statusMessage = 'Classifying document with AI...';
      });

      DocumentClassification classification;
      try {
        classification = await classificationService.classifyDocument(documentText);
      } on DocumentClassificationException {
        setState(() {
          _statusMessage = 'Retrying classification...';
        });
        try {
          classification = await classificationService.classifyDocument(documentText);
        } on DocumentClassificationException catch (e) {
          setState(() {
            _error = e.message;
            _step = UploadStep.manualClassify;
            _statusMessage = null;
          });
          return;
        }
      }

      await _navigateToReview(
        fileName: file.name,
        classification: classification,
        matchingService: matchingService,
        repository: repository,
      );
    } on AppException catch (e) {
      setState(() {
        _error = e.message;
        _step = UploadStep.error;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong while processing the document.';
        _step = UploadStep.error;
      });
    }
  }

  Future<void> _continueWithManualType() async {
    if (_documentId == null || _storagePath == null || _selectedFile == null) {
      setState(() {
        _error = 'Upload session expired. Please select the file again.';
        _step = UploadStep.error;
      });
      return;
    }

    final matchingService = ref.read(propertyMatchingServiceProvider);
    final repository = ref.read(supabaseRepositoryProvider);

    await _navigateToReview(
      fileName: _selectedFile!.name,
      classification: DocumentClassification.manual(documentType: _manualType),
      matchingService: matchingService,
      repository: repository,
      isManualClassification: true,
    );
  }

  Future<void> _retryClassification() async {
    if (_selectedFile == null) {
      await _pickAndProcess();
      return;
    }
    await _processFile(_selectedFile!);
  }

  Future<void> _navigateToReview({
    required String fileName,
    required DocumentClassification classification,
    required PropertyMatchingService matchingService,
    required SupabaseRepository repository,
    bool isManualClassification = false,
  }) async {
    setState(() {
      _step = UploadStep.matching;
      _statusMessage = 'Matching property...';
      _error = null;
    });

    final properties = await repository.fetchProperties();
    final matchResult = matchingService.findMatch(
      classification.addressHint,
      properties,
    );

    final draft = DocumentUploadDraft(
      documentId: _documentId!,
      storagePath: _storagePath!,
      fileName: fileName,
      classification: classification,
      matchResult: matchResult,
      documentType: isManualClassification ? _manualType : null,
      isManualClassification: isManualClassification,
    );

    setState(() {
      _step = UploadStep.done;
      _statusMessage = 'Ready for review.';
    });

    if (mounted) {
      context.push('/review', extra: draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = _step == UploadStep.uploading ||
        _step == UploadStep.extracting ||
        _step == UploadStep.classifying ||
        _step == UploadStep.matching;

    return SecondaryScaffold(
      title: widget.onboardingMode ? 'Onboard New Property' : 'Upload Document',
      onBack: isProcessing ? () {} : () => context.go('/dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PropVaultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.onboardingMode
                        ? 'Start with your settlement statement'
                        : 'Upload a property document',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.onboardingMode
                        ? 'Upload your closing settlement (HUD-1 / ALTA) first. We\'ll build the property profile and a checklist of mortgage, lease, insurance, and HOA documents to collect next.'
                        : 'We classify leases, deeds, insurance, utility bills, and other documents, then link them to the matching property after your review.',
                  ),
                  if (_step != UploadStep.manualClassify) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: isProcessing ? null : _pickAndProcess,
                      icon: Icon(widget.onboardingMode ? Icons.receipt_long : Icons.upload_file),
                      label: Text(widget.onboardingMode ? 'Select settlement PDF' : 'Select PDF'),
                    ),
                  ],
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 12),
                    Text('Selected: ${_selectedFile!.name}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isProcessing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(_statusMessage ?? 'Processing...'),
            ],
            if (_step == UploadStep.manualClassify) ...[
              PropVaultCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Automatic classification unavailable',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ??
                            'We could not classify this document automatically. Choose the document type to continue.',
                      ),
                      const SizedBox(height: 20),
                      DocumentTypeField(
                        value: _manualType,
                        label: 'What type of document is this?',
                        onChanged: (type) {
                          if (type != null) {
                            setState(() => _manualType = type);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _continueWithManualType,
                        child: const Text('Continue to review'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _retryClassification,
                        child: const Text('Retry automatic classification'),
                      ),
                    ],
                  ),
                ),
            ],
            if (_step == UploadStep.error && _error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _selectedFile == null
                    ? _pickAndProcess
                    : () => _processFile(_selectedFile!),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
