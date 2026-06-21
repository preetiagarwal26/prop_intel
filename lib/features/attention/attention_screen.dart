import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/action_item.dart';
import '../shared/action_item_tile.dart';

class AttentionScreen extends ConsumerWidget {
  const AttentionScreen({super.key});

  Future<void> _updateStatus(
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
    final attentionAsync = ref.watch(attentionProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Needs Attention'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: attentionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load action items: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(attentionProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All caught up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No open action items. Upload documents to get AI-generated todos.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${items.length} item(s) need your attention',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => ActionItemTile(
                  item: item,
                  dateFormat: dateFormat,
                  onTap: item.propertyId != null
                      ? () => context.push('/property/${item.propertyId}')
                      : null,
                  onMarkDone: () => _updateStatus(ref, item, ActionItemStatus.done),
                  onDismiss: () => _updateStatus(ref, item, ActionItemStatus.dismissed),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
