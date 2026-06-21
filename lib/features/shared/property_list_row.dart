import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/property_status_service.dart';
import 'property_status_pill.dart';

class PropertyListRow extends StatelessWidget {
  const PropertyListRow({
    super.key,
    required this.entry,
    required this.status,
    this.onTap,
  });

  final PortfolioEntry entry;
  final PropertyStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency();
    final rentLabel = status.monthlyRent != null
        ? '${currency.format(status.monthlyRent)}/mo'
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _iconFor(entry.property.propertyAddress),
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.property.propertyAddress,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.property.city}, ${entry.property.state}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (rentLabel != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rentLabel, style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success)),
                  Text(
                    'rent',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 12),
            PropertyStatusPill(status: status),
          ],
        ),
      ),
    );
  }

  String _iconFor(String address) {
    const icons = ['🏠', '🏢', '🏬', '🏘', '🏗'];
    return icons[address.hashCode.abs() % icons.length];
  }
}
