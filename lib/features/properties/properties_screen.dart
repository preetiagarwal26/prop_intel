import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/property_status_service.dart';
import '../shared/property_status_pill.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final statusService = ref.watch(propertyStatusServiceProvider);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
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
      body: portfolioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load properties: $error')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No properties yet. Upload a document to get started.'));
          }

          final docCount = entries.fold<int>(0, (sum, e) => sum + e.documents.length);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${entries.length} propert${entries.length == 1 ? 'y' : 'ies'} · $docCount document${docCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: crossAxisCount == 1 ? 1.8 : 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          final status = statusService.resolve(
                            property: entry.property,
                            leases: entry.leases,
                          );

                          return _PropertyGridCard(
                            entry: entry,
                            status: status,
                            currency: currency,
                            onTap: () => context.push('/property/${entry.property.id}'),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PropertyGridCard extends StatelessWidget {
  const _PropertyGridCard({
    required this.entry,
    required this.status,
    required this.currency,
    required this.onTap,
  });

  final PortfolioEntry entry;
  final PropertyStatus status;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const icons = ['🏠', '🏢', '🏬', '🏘', '🏗'];
    final icon = icons[entry.property.propertyAddress.hashCode.abs() % icons.length];
    final rentLabel = status.monthlyRent != null
        ? currency.format(status.monthlyRent)
        : '—';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                entry.property.propertyAddress,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${entry.property.city}, ${entry.property.state}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              _InfoRow(label: 'Documents', value: '${entry.documents.length}'),
              _InfoRow(label: 'Monthly rent', value: rentLabel),
              const SizedBox(height: 8),
              PropertyStatusPill(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
