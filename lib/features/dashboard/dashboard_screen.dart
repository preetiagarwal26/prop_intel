import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/action_item.dart';
import '../../data/models/onboarding_status.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/portfolio_metrics_service.dart';
import '../../services/property_status_service.dart';
import '../shared/action_item_tile.dart';
import '../shared/app_shell.dart';
import '../shared/metric_card.dart';
import '../shared/property_list_row.dart';
import '../shared/prop_vault_card.dart';

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
    final subtitleDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return AppShell(
      currentNav: AppNav.dashboard,
      title: 'Portfolio Overview',
      subtitle: portfolioAsync.maybeWhen(
        data: (entries) =>
            '$subtitleDate · ${entries.length} propert${entries.length == 1 ? 'y' : 'ies'}',
        orElse: () => subtitleDate,
      ),
      actions: const [PropVaultTopActions(showOnboardEntry: true)],
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
                      'Upload a settlement statement to create your first property profile and closing checklist.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push('/upload?onboarding=1'),
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Onboard new property'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.push('/upload'),
                      child: const Text('Upload other document'),
                    ),
                  ],
                ),
              ),
            );
          }

          final onboardingEntries = entries
              .where((e) => e.property.onboardingStatus == OnboardingStatus.inProgress)
              .toList();

          final attentionItems = attentionAsync.valueOrNull ?? const [];
          final metrics = metricsService.compute(
            entries: entries,
            openActionItems: attentionItems,
          );
          final currency = NumberFormat.simpleCurrency();

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (onboardingEntries.isNotEmpty) ...[
                    _OnboardingPanel(entries: onboardingEntries),
                    const SizedBox(height: 24),
                  ],
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

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({required this.entries});

  final List<PortfolioEntry> entries;

  @override
  Widget build(BuildContext context) {
    return PropVaultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PropVaultPanelHeader(
            title: 'Closing onboarding',
            subtitle: 'Properties still collecting closing documents',
          ),
          ...entries.map((entry) {
            final property = entry.property;
            final pending = property.onboardingChecklist.pendingItems;
            final nextLabel = pending.isEmpty ? null : pending.first.label;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                child: const Icon(Icons.receipt_long, color: AppColors.gold, size: 20),
              ),
              title: Text(property.displayAddress),
              subtitle: Text(
                nextLabel == null
                    ? 'Checklist in progress'
                    : 'Next: upload $nextLabel',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/property/${property.id}'),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/upload?onboarding=1'),
              icon: const Icon(Icons.add),
              label: const Text('Onboard another property'),
            ),
          ),
        ],
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
    return PropVaultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropVaultPanelHeader(
            title: 'Properties',
            subtitle: 'Current portfolio · status & rent',
            trailing: TextButton(onPressed: onViewAll, child: const Text('View all')),
          ),
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
    return PropVaultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropVaultPanelHeader(
            title: 'Notifications',
            subtitle: 'Upcoming & urgent',
            trailing: openCount > 0
                ? TextButton(onPressed: onViewAll, child: Text('View all ($openCount)'))
                : null,
          ),
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
    );
  }
}

class _IncomePlaceholder extends StatelessWidget {
  static const _barHeights = [0.52, 0.58, 0.55, 0.62, 0.60, 0.68, 0.71, 0.74, 0.70, 0.78, 0.82, 1.0];

  @override
  Widget build(BuildContext context) {
    return PropVaultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PropVaultPanelHeader(
            title: 'Income trend',
            subtitle: 'Monthly rental income — coming in Phase 4',
          ),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final height in _barHeights)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FractionallySizedBox(
                        heightFactor: height,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: height == 1.0 ? 1 : 0.7),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rent schedule data required',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}
