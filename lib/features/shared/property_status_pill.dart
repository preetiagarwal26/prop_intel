import 'package:flutter/material.dart';

import '../../services/property_status_service.dart';

class PropertyStatusPill extends StatelessWidget {
  const PropertyStatusPill({
    super.key,
    required this.status,
    this.now,
  });

  final PropertyStatus status;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status.kind, Theme.of(context).colorScheme);
    final subtitle = status.subtitle(now ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        subtitle != null ? '${status.label} · $subtitle' : status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  _PillColors _colorsFor(PropertyStatusKind kind, ColorScheme scheme) {
    return switch (kind) {
      PropertyStatusKind.rented => _PillColors(
          background: scheme.primaryContainer.withValues(alpha: 0.55),
          foreground: scheme.onPrimaryContainer,
        ),
      PropertyStatusKind.leaseEnding => _PillColors(
          background: scheme.tertiaryContainer.withValues(alpha: 0.65),
          foreground: scheme.onTertiaryContainer,
        ),
      PropertyStatusKind.vacant => _PillColors(
          background: scheme.errorContainer.withValues(alpha: 0.55),
          foreground: scheme.onErrorContainer,
        ),
      PropertyStatusKind.noLeaseOnFile => _PillColors(
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        ),
    };
  }
}

class _PillColors {
  const _PillColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
