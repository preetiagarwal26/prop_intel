import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/action_item.dart';
import '../../data/models/document.dart';
import '../../data/models/document_type.dart';
import '../../data/models/occupancy_status.dart';
import '../shared/action_item_tile.dart';
import '../shared/document_type_field.dart';
import '../shared/property_status_pill.dart';

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  Future<void> _updateActionStatus(
    WidgetRef ref,
    ActionItem item,
    ActionItemStatus status,
  ) async {
    final repository = ref.read(supabaseRepositoryProvider);
    await repository.updateActionItemStatus(
      actionItemId: item.id,
      status: status,
    );
    ref.invalidate(attentionProvider);
    ref.invalidate(portfolioProvider);
    ref.invalidate(propertyDetailProvider(propertyId));
  }

  Future<void> _updateOccupancy(
    WidgetRef ref,
    OccupancyStatus? occupancyStatus,
  ) async {
    final repository = ref.read(supabaseRepositoryProvider);
    await repository.updatePropertyOccupancy(
      propertyId: propertyId,
      occupancyStatus: occupancyStatus,
    );
    ref.invalidate(portfolioProvider);
    ref.invalidate(propertyDetailProvider(propertyId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(propertyDetailProvider(propertyId));
    final statusService = ref.watch(propertyStatusServiceProvider);
    final dateFormat = DateFormat.yMMMd();
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/upload'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load property: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(propertyDetailProvider(propertyId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          final status = statusService.resolve(
            property: detail.property,
            leases: detail.leases,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.property.displayAddress,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${detail.documents.length} document(s) · ${detail.leases.length} lease(s)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      PropertyStatusPill(status: status),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _updateOccupancy(
                              ref,
                              OccupancyStatus.vacant,
                            ),
                            child: const Text('Mark vacant'),
                          ),
                          OutlinedButton(
                            onPressed: () => _updateOccupancy(
                              ref,
                              OccupancyStatus.rented,
                            ),
                            child: const Text('Mark rented'),
                          ),
                          TextButton(
                            onPressed: () => _updateOccupancy(ref, null),
                            child: const Text('Auto-detect'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (detail.actionItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Needs Attention', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...detail.actionItems.map(
                  (item) => ActionItemTile(
                    item: item,
                    dateFormat: dateFormat,
                    compact: true,
                    onMarkDone: () =>
                        _updateActionStatus(ref, item, ActionItemStatus.done),
                    onDismiss: () =>
                        _updateActionStatus(ref, item, ActionItemStatus.dismissed),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Documents', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (detail.documents.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No documents uploaded for this property yet.'),
                  ),
                )
              else
                ...detail.documents.map(
                  (document) => _DocumentTile(
                    document: document,
                    dateFormat: dateFormat,
                    onTap: () => context.push(
                      '/property/$propertyId/document/${document.id}',
                    ),
                    onOpen: () => _openDocument(context, ref, document),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Leases', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (detail.leases.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No leases linked yet.'),
                  ),
                )
              else
                ...detail.leases.map((lease) {
                  final rent = lease.monthlyRent != null
                      ? currency.format(lease.monthlyRent)
                      : 'Rent N/A';
                  final start = lease.leaseStartDate != null
                      ? dateFormat.format(lease.leaseStartDate!)
                      : 'Start N/A';
                  final end = lease.leaseEndDate != null
                      ? dateFormat.format(lease.leaseEndDate!)
                      : 'End N/A';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('$rent / month'),
                      subtitle: Text(
                        '$start - $end\nTenants: ${lease.tenantNames.join(', ')}',
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    try {
      final repository = ref.read(supabaseRepositoryProvider);
      final url = await repository.getDocumentSignedUrl(document.storagePath);
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download link copied to clipboard. Paste in browser to open.'),
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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.dateFormat,
    required this.onTap,
    required this.onOpen,
  });

  final Document document;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final type = document.documentType ?? DocumentType.other;
    final uploaded = document.uploadedAt != null
        ? dateFormat.format(document.uploadedAt!)
        : 'Unknown date';
    final subtitle = document.summary?.trim().isNotEmpty == true
        ? document.summary!
        : _metadataSummary(document.extractedMetadata);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(iconForDocumentType(type)),
        title: Text(document.fileName),
        subtitle: Text(
          '${type.label} · $uploaded'
          '${document.flags.isNotEmpty ? ' · ${document.flags.length} flag(s)' : ''}'
          '${subtitle.isNotEmpty ? '\n$subtitle' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Get download link',
          onPressed: onOpen,
        ),
        isThreeLine: subtitle.isNotEmpty,
      ),
    );
  }

  String _metadataSummary(Map<String, dynamic> metadata) {
    const priorityKeys = [
      'expiry_date',
      'due_date',
      'policy_number',
      'amount_due',
      'monthly_rent',
      'carrier',
      'provider',
    ];

    for (final key in priorityKeys) {
      final value = metadata[key];
      if (value != null && value.toString().isNotEmpty) {
        return '${_formatKey(key)}: $value';
      }
    }
    return '';
  }

  String _formatKey(String key) {
    return key
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
