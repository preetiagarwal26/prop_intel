import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/document_classification.dart';
import '../../data/models/document_upload_draft.dart';

enum UploadStep { idle, uploading, extracting, classifying, matching, done, error }

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  UploadStep _step = UploadStep.idle;
  String? _error;
  String? _statusMessage;
  PlatformFile? _selectedFile;

  Future<void> _pickAndProcess() async {
    setState(() {
      _error = null;
      _statusMessage = null;
      _step = UploadStep.idle;
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
      });

      final uploadResult = await storageService.uploadDocument(
        fileName: file.name,
        bytes: file.bytes!,
      );

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
        classification = await classificationService.classifyDocument(documentText);
      }

      setState(() {
        _step = UploadStep.matching;
        _statusMessage = 'Matching property...';
      });

      final properties = await repository.fetchProperties();
      final matchResult = matchingService.findMatch(
        classification.addressHint,
        properties,
      );

      final draft = DocumentUploadDraft(
        documentId: uploadResult.document.id,
        storagePath: uploadResult.storagePath,
        fileName: file.name,
        classification: classification,
        matchResult: matchResult,
      );

      setState(() {
        _step = UploadStep.done;
        _statusMessage = 'Classification complete.';
      });

      if (mounted) {
        context.push('/review', extra: draft);
      }
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

  @override
  Widget build(BuildContext context) {
    final isProcessing = _step != UploadStep.idle &&
        _step != UploadStep.error &&
        _step != UploadStep.done;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isProcessing ? null : () => context.go('/portfolio'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload a property document',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We classify leases, deeds, insurance, utility bills, and other documents, then link them to the matching property after your review.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: isProcessing ? null : _pickAndProcess,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select PDF'),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 12),
                      Text('Selected: ${_selectedFile!.name}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isProcessing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(_statusMessage ?? 'Processing...'),
            ],
            if (_error != null) ...[
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
