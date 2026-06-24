import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/onboarding_checklist.dart';
import '../../data/models/onboarding_status.dart';
import '../../data/models/property.dart';
import 'prop_vault_card.dart';

class OnboardingChecklistPanel extends StatelessWidget {
  const OnboardingChecklistPanel({
    super.key,
    required this.property,
    this.onComplete,
    this.onUploadNext,
  });

  final Property property;
  final VoidCallback? onComplete;
  final VoidCallback? onUploadNext;

  @override
  Widget build(BuildContext context) {
    if (property.onboardingStatus == OnboardingStatus.none &&
        !property.onboardingChecklist.hasOnboarding) {
      return const SizedBox.shrink();
    }

    final pending = property.onboardingChecklist.pendingItems;
    final isComplete = property.onboardingStatus == OnboardingStatus.complete ||
        property.onboardingChecklist.isComplete;

    return PropVaultCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Closing onboarding', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            isComplete
                ? 'All expected closing documents received.'
                : '${pending.length} document(s) still expected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text3),
          ),
          if (property.propertyType != null ||
              property.bedrooms != null ||
              property.bathrooms != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (property.propertyType != null)
                  Chip(label: Text(property.propertyType!.label)),
                if (property.bedrooms != null)
                  Chip(label: Text('${property.bedrooms} bed')),
                if (property.bathrooms != null)
                  Chip(label: Text('${property.bathrooms} bath')),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ...OnboardingDocKey.values.map((key) {
            final expected = property.onboardingChecklist.expected[key.value] == true;
            final received = property.onboardingChecklist.received[key.value] == true;
            if (!expected && !received) {
              return const SizedBox.shrink();
            }
            return _ChecklistRow(
              label: key.label,
              received: received,
              expected: expected,
            );
          }),
          if (!isComplete && pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onUploadNext,
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text('Upload ${pending.first.label}'),
            ),
          ],
          if (!isComplete &&
              onComplete != null &&
              property.onboardingStatus == OnboardingStatus.inProgress) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onComplete, child: const Text('Mark onboarding complete')),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.received,
    required this.expected,
  });

  final String label;
  final bool received;
  final bool expected;

  @override
  Widget build(BuildContext context) {
    final icon = received
        ? Icons.check_circle
        : expected
            ? Icons.radio_button_unchecked
            : Icons.check_circle_outline;
    final color = received ? AppColors.success : AppColors.text3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          if (received)
            Text('Received', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}
