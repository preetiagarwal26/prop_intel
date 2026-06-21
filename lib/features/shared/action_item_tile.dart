import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/action_item.dart';
import '../../data/models/document_flag.dart';
import 'document_metadata_helpers.dart';

class ActionItemTile extends StatelessWidget {
  const ActionItemTile({
    super.key,
    required this.item,
    required this.dateFormat,
    this.onDismiss,
    this.onMarkDone,
    this.onTap,
    this.compact = false,
  });

  final ActionItem item;
  final DateFormat dateFormat;
  final VoidCallback? onDismiss;
  final VoidCallback? onMarkDone;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dueLabel = item.dueDate != null
        ? dateFormat.format(item.dueDate!)
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(
                  color: flagSeverityColor(_mapSeverity(item.severity)),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (dueLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Due $dueLabel',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact && (onDismiss != null || onMarkDone != null))
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'done') {
                      onMarkDone?.call();
                    } else if (value == 'dismiss') {
                      onDismiss?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onMarkDone != null)
                      const PopupMenuItem(value: 'done', child: Text('Mark done')),
                    if (onDismiss != null)
                      const PopupMenuItem(value: 'dismiss', child: Text('Dismiss')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  DocumentFlagSeverity _mapSeverity(ActionItemSeverity severity) {
    return switch (severity) {
      ActionItemSeverity.critical => DocumentFlagSeverity.critical,
      ActionItemSeverity.warning => DocumentFlagSeverity.warning,
      ActionItemSeverity.info => DocumentFlagSeverity.info,
    };
  }
}
