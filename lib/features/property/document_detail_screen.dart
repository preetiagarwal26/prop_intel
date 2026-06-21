import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/document_type.dart';
import '../shared/document_intelligence_panel.dart';
import '../shared/document_metadata_helpers.dart';
import '../shared/document_type_field.dart';

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({
    super.key,
    required this.propertyId,
    required this.documentId,
  });

  final String propertyId;
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailKey = DocumentDetailKey(propertyId: propertyId, documentId: documentId);
    final detailAsync = ref.watch(documentDetailProvider(detailKey));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/property/$propertyId'),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load document: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(documentDetailProvider(detailKey)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final doc = detail.document;
          final type = doc.documentType ?? DocumentType.other;
          final uploaded = doc.uploadedAt != null
              ? dateFormat.format(doc.uploadedAt!)
              : 'Unknown date';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(iconForDocumentType(type)),
                  title: Text(doc.fileName),
                  subtitle: Text(
                    '${type.label} · $uploaded\n${detail.property.displayAddress}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Copy download link',
                    onPressed: () => _copyDownloadLink(context, ref, doc.storagePath),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DocumentIntelligencePanel(
                summary: doc.summary,
                keyPoints: doc.keyPoints,
                flags: doc.flags,
              ),
              if (doc.extractedMetadata.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Extracted details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: doc.extractedMetadata.entries.map((entry) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(formatMetadataKey(entry.key)),
                          subtitle: Text(metadataValueAsString(entry.value)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _copyDownloadLink(
    BuildContext context,
    WidgetRef ref,
    String storagePath,
  ) async {
    try {
      final repository = ref.read(supabaseRepositoryProvider);
      final url = await repository.getDocumentSignedUrl(storagePath);
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download link copied to clipboard.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $e')),
        );
      }
    }
  }
}
