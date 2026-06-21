import 'package:flutter/material.dart';

import '../../data/models/document_flag.dart';
import '../shared/document_metadata_helpers.dart';

class DocumentIntelligencePanel extends StatelessWidget {
  const DocumentIntelligencePanel({
    super.key,
    this.summary,
    this.keyPoints = const [],
    this.flags = const [],
    this.compact = false,
  });

  final String? summary;
  final List<String> keyPoints;
  final List<DocumentFlag> flags;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasSummary = summary != null && summary!.trim().isNotEmpty;
    final hasPoints = keyPoints.isNotEmpty;
    final hasFlags = flags.isNotEmpty;

    if (!hasSummary && !hasPoints && !hasFlags) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No AI summary available for this document.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSummary) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('AI Summary', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(summary!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          if (!compact) const SizedBox(height: 12),
        ],
        if (hasPoints) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key points', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  ...keyPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 7, right: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(child: Text(point)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!compact) const SizedBox(height: 12),
        ],
        if (hasFlags)
          ...flags.map(
            (flag) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: flagSeverityBackground(flag.severity),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: flagSeverityColor(flag.severity), width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flag.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: flagSeverityColor(flag.severity),
                      ),
                    ),
                    if (flag.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(flag.description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
