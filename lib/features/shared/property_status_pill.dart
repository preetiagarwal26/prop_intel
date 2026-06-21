import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
    final colors = _colorsFor(status.kind);
    final subtitle = status.subtitle(now ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        subtitle != null ? '${status.label} · $subtitle' : status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
      ),
    );
  }

  _PillColors _colorsFor(PropertyStatusKind kind) {
    return switch (kind) {
      PropertyStatusKind.rented => const _PillColors(
          background: AppColors.successBg,
          foreground: AppColors.successText,
        ),
      PropertyStatusKind.leaseEnding => const _PillColors(
          background: AppColors.warnBg,
          foreground: AppColors.warnText,
        ),
      PropertyStatusKind.vacant => const _PillColors(
          background: AppColors.dangerBg,
          foreground: AppColors.dangerText,
        ),
      PropertyStatusKind.noLeaseOnFile => const _PillColors(
          background: AppColors.surface2,
          foreground: AppColors.text2,
        ),
    };
  }
}

class _PillColors {
  const _PillColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
