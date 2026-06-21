import '../../data/models/lease.dart';
import '../../data/models/occupancy_status.dart';
import '../../data/models/property.dart';

enum PropertyStatusKind {
  rented,
  leaseEnding,
  noLeaseOnFile,
  vacant,
}

class PropertyStatus {
  const PropertyStatus({
    required this.kind,
    this.leaseEndDate,
    this.monthlyRent,
  });

  final PropertyStatusKind kind;
  final DateTime? leaseEndDate;
  final double? monthlyRent;

  String get label => switch (kind) {
        PropertyStatusKind.rented => 'Rented',
        PropertyStatusKind.leaseEnding => 'Lease ending',
        PropertyStatusKind.noLeaseOnFile => 'No lease on file',
        PropertyStatusKind.vacant => 'Vacant',
      };

  String? subtitle(DateTime now) {
    return switch (kind) {
      PropertyStatusKind.rented when leaseEndDate != null =>
        'Until ${_formatMonthYear(leaseEndDate!)}',
      PropertyStatusKind.leaseEnding when leaseEndDate != null =>
        'Ends ${_formatMonthDay(leaseEndDate!)}',
      PropertyStatusKind.noLeaseOnFile => 'Upload a lease to track status',
      PropertyStatusKind.vacant => 'Marked vacant',
      _ => null,
    };
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthDay(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class PropertyStatusService {
  static const leaseEndingDays = 60;

  PropertyStatus resolve({
    required Property property,
    required List<Lease> leases,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    if (property.occupancyStatus == OccupancyStatus.vacant) {
      return PropertyStatus(
        kind: PropertyStatusKind.vacant,
        monthlyRent: _latestRent(leases),
      );
    }

    final activeLease = _findActiveLease(leases, today);
    if (activeLease == null) {
      return PropertyStatus(
        kind: PropertyStatusKind.noLeaseOnFile,
        monthlyRent: _latestRent(leases),
      );
    }

    final endDate = activeLease.leaseEndDate != null
        ? _dateOnly(activeLease.leaseEndDate!)
        : null;
    final daysUntilEnd = endDate?.difference(today).inDays;

    if (endDate != null &&
        daysUntilEnd != null &&
        daysUntilEnd >= 0 &&
        daysUntilEnd <= leaseEndingDays) {
      return PropertyStatus(
        kind: PropertyStatusKind.leaseEnding,
        leaseEndDate: endDate,
        monthlyRent: activeLease.monthlyRent,
      );
    }

    return PropertyStatus(
      kind: PropertyStatusKind.rented,
      leaseEndDate: endDate,
      monthlyRent: activeLease.monthlyRent,
    );
  }

  Lease? _findActiveLease(List<Lease> leases, DateTime today) {
    Lease? best;
    for (final lease in leases) {
      final end = lease.leaseEndDate != null ? _dateOnly(lease.leaseEndDate!) : null;
      final start = lease.leaseStartDate != null ? _dateOnly(lease.leaseStartDate!) : null;

      final isActive = (end == null || !end.isBefore(today)) &&
          (start == null || !start.isAfter(today));

      if (!isActive) {
        continue;
      }

      if (best == null) {
        best = lease;
        continue;
      }

      final bestEnd = best.leaseEndDate;
      final leaseEnd = lease.leaseEndDate;
      if (bestEnd == null) {
        continue;
      }
      if (leaseEnd == null || leaseEnd.isAfter(bestEnd)) {
        best = lease;
      }
    }
    return best;
  }

  double? _latestRent(List<Lease> leases) {
    for (final lease in leases) {
      if (lease.monthlyRent != null) {
        return lease.monthlyRent;
      }
    }
    return null;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
