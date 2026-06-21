import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
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
    final severity = _mapSeverity(item.severity);
    final dueLabel = item.dueDate != null ? dateFormat.format(item.dueDate!) : null;

    if (compact) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SeverityIcon(severity: severity),
              const SizedBox(width: 10),
              Expanded(
                child: _ItemText(
                  title: item.title,
                  description: item.description,
                  dueLabel: dueLabel,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PropVaultActionCard(
      onTap: onTap,
      severity: severity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeverityIcon(severity: severity),
          const SizedBox(width: 10),
          Expanded(
            child: _ItemText(
              title: item.title,
              description: item.description,
              dueLabel: dueLabel,
            ),
          ),
          if (onDismiss != null || onMarkDone != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.text3),
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

class PropVaultActionCard extends StatelessWidget {
  const PropVaultActionCard({
    super.key,
    required this.severity,
    required this.child,
    this.onTap,
  });

  final DocumentFlagSeverity severity;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class _SeverityIcon extends StatelessWidget {
  const _SeverityIcon({required this.severity});

  final DocumentFlagSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: flagSeverityBackground(severity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _iconFor(severity),
        size: 14,
        color: flagSeverityColor(severity),
      ),
    );
  }

  IconData _iconFor(DocumentFlagSeverity severity) {
    return switch (severity) {
      DocumentFlagSeverity.critical => Icons.error_outline,
      DocumentFlagSeverity.warning => Icons.warning_amber_outlined,
      DocumentFlagSeverity.info => Icons.info_outline,
    };
  }
}

class _ItemText extends StatelessWidget {
  const _ItemText({
    required this.title,
    required this.description,
    required this.dueLabel,
  });

  final String title;
  final String? description;
  final String? dueLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text3),
          ),
        ],
        if (dueLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            'Due $dueLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text3),
          ),
        ],
      ],
    );
  }
}
