import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final currency = NumberFormat.simpleCurrency();
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/upload'),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      ),
      body: portfolioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load portfolio: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(portfolioProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_work_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No properties yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload your first document to create a property and document vault.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final docTypes = entry.documents
                  .map((doc) => doc.documentType?.label ?? 'Document')
                  .toSet()
                  .take(3)
                  .join(', ');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/property/${entry.property.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.property.displayAddress,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${entry.documents.length} document(s)'
                          '${docTypes.isNotEmpty ? ' · $docTypes' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (entry.leases.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...entry.leases.take(2).map((lease) {
                            final rent = lease.monthlyRent != null
                                ? currency.format(lease.monthlyRent)
                                : 'Rent N/A';
                            final start = lease.leaseStartDate != null
                                ? dateFormat.format(lease.leaseStartDate!)
                                : 'Start N/A';
                            final end = lease.leaseEndDate != null
                                ? dateFormat.format(lease.leaseEndDate!)
                                : 'End N/A';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$rent / month · $start - $end',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
