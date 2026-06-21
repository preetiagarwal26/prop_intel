import '../../data/models/action_item.dart';
import '../../data/repositories/supabase_repository.dart';
import 'property_status_service.dart';

class PortfolioMetrics {
  const PortfolioMetrics({
    required this.propertyCount,
    required this.documentCount,
    required this.leasesExpiringWithin30Days,
    required this.openActionItemsCount,
    required this.monthlyRentTotal,
  });

  final int propertyCount;
  final int documentCount;
  final int leasesExpiringWithin30Days;
  final int openActionItemsCount;
  final double monthlyRentTotal;
}

class PortfolioMetricsService {
  PortfolioMetricsService(this._propertyStatusService);

  final PropertyStatusService _propertyStatusService;

  PortfolioMetrics compute({
    required List<PortfolioEntry> entries,
    required List<ActionItem> openActionItems,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final expiringCutoff = today.add(const Duration(days: 30));
    var documentCount = 0;
    var leasesExpiring = 0;
    var monthlyRentTotal = 0.0;

    for (final entry in entries) {
      documentCount += entry.documents.length;

      final status = _propertyStatusService.resolve(
        property: entry.property,
        leases: entry.leases,
        now: today,
      );
      if (status.monthlyRent != null) {
        monthlyRentTotal += status.monthlyRent!;
      }

      final endDate = status.leaseEndDate;
      if (status.kind == PropertyStatusKind.leaseEnding &&
          endDate != null &&
          !endDate.isAfter(expiringCutoff)) {
        leasesExpiring++;
      }
    }

    return PortfolioMetrics(
      propertyCount: entries.length,
      documentCount: documentCount,
      leasesExpiringWithin30Days: leasesExpiring,
      openActionItemsCount: openActionItems.length,
      monthlyRentTotal: monthlyRentTotal,
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
