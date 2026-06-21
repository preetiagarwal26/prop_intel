import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/action_item.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/portfolio_metrics_service.dart';
import '../../services/property_status_service.dart';
import '../shared/action_item_tile.dart';
import '../shared/metric_card.dart';
import '../shared/property_list_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
    if (item.propertyId != null) {
      ref.invalidate(propertyDetailProvider(item.propertyId!));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final attentionAsync = ref.watch(attentionProvider);
    final statusService = ref.watch(propertyStatusServiceProvider);
    final metricsService = ref.watch(portfolioMetricsServiceProvider);
    final dateFormat = DateFormat.yMMMd();
    final openCount = attentionAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Overview'),
        actions: [
          IconButton(
            tooltip: 'All properties',
            onPressed: () => context.push('/properties'),
            icon: const Icon(Icons.grid_view_outlined),
          ),
          IconButton(
            tooltip: 'Needs attention',
            onPressed: () => context.push('/attention'),
            icon: Badge(
              isLabelVisible: openCount > 0,
              label: Text('$openCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
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
                Text('Failed to load dashboard: $error'),
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

          final attentionItems = attentionAsync.valueOrNull ?? const [];
          final metrics = metricsService.compute(
            entries: entries,
            openActionItems: attentionItems,
          );
          final currency = NumberFormat.simpleCurrency();
          final subtitleDate = DateFormat('EEEE, MMM d').format(DateTime.now());

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  Text(
                    '$subtitleDate · ${metrics.propertyCount} propert${metrics.propertyCount == 1 ? 'y' : 'ies'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _MetricsGrid(
                    wide: wide,
                    metrics: metrics,
                    currency: currency,
                  ),
                  const SizedBox(height: 24),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _PropertiesPanel(
                            entries: entries,
                            statusService: statusService,
                            onViewAll: () => context.push('/properties'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _AttentionPanel(
                            items: attentionItems,
                            openCount: openCount,
                            dateFormat: dateFormat,
                            onViewAll: () => context.push('/attention'),
                            onItemTap: (item) {
                              if (item.propertyId != null) {
                                context.push('/property/${item.propertyId}');
                              }
                            },
                            onMarkDone: (item) =>
                                _updateActionStatus(ref, item, ActionItemStatus.done),
                            onDismiss: (item) => _updateActionStatus(
                              ref,
                              item,
                              ActionItemStatus.dismissed,
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _PropertiesPanel(
                      entries: entries,
                      statusService: statusService,
                      onViewAll: () => context.push('/properties'),
                    ),
                    const SizedBox(height: 16),
                    _AttentionPanel(
                      items: attentionItems,
                      openCount: openCount,
                      dateFormat: dateFormat,
                      onViewAll: () => context.push('/attention'),
                      onItemTap: (item) {
                        if (item.propertyId != null) {
                          context.push('/property/${item.propertyId}');
                        }
                      },
                      onMarkDone: (item) =>
                          _updateActionStatus(ref, item, ActionItemStatus.done),
                      onDismiss: (item) =>
                          _updateActionStatus(ref, item, ActionItemStatus.dismissed),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _IncomePlaceholder(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.wide,
    required this.metrics,
    required this.currency,
  });

  final bool wide;
  final PortfolioMetrics metrics;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricCard(
        label: 'Properties',
        value: '${metrics.propertyCount}',
        subtitle: 'In your portfolio',
      ),
      MetricCard(
        label: 'Documents',
        value: '${metrics.documentCount}',
        subtitle: 'Stored in vault',
      ),
      MetricCard(
        label: 'Leases expiring',
        value: '${metrics.leasesExpiringWithin30Days}',
        subtitle: 'Within 30 days',
      ),
      MetricCard(
        label: 'Needs attention',
        value: '${metrics.openActionItemsCount}',
        subtitle: metrics.monthlyRentTotal > 0
            ? '${currency.format(metrics.monthlyRentTotal)}/mo tracked rent'
            : 'Open action items',
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: cards,
    );
  }
}

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({
    required this.entries,
    required this.statusService,
    required this.onViewAll,
  });

  final List<PortfolioEntry> entries;
  final PropertyStatusService statusService;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Properties', style: Theme.of(context).textTheme.titleLarge),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
            Text(
              'Current portfolio · status & rent',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            ...entries.map((entry) {
              final status = statusService.resolve(
                property: entry.property,
                leases: entry.leases,
              );
              return PropertyListRow(
                entry: entry,
                status: status,
                onTap: () => context.push('/property/${entry.property.id}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({
    required this.items,
    required this.openCount,
    required this.dateFormat,
    required this.onViewAll,
    required this.onItemTap,
    required this.onMarkDone,
    required this.onDismiss,
  });

  final List<ActionItem> items;
  final int openCount;
  final DateFormat dateFormat;
  final VoidCallback onViewAll;
  final ValueChanged<ActionItem> onItemTap;
  final ValueChanged<ActionItem> onMarkDone;
  final ValueChanged<ActionItem> onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
                if (openCount > 0)
                  TextButton(onPressed: onViewAll, child: Text('View all ($openCount)')),
              ],
            ),
            Text(
              'Upcoming & urgent',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'All caught up — no open items.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...items.take(5).map(
                    (item) => ActionItemTile(
                      item: item,
                      dateFormat: dateFormat,
                      compact: true,
                      onTap: () => onItemTap(item),
                      onMarkDone: () => onMarkDone(item),
                      onDismiss: () => onDismiss(item),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _IncomePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Monthly rental income chart — coming in Phase 4',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rent schedule data required',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
