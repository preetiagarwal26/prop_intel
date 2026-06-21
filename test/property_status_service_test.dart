import 'package:flutter_test/flutter_test.dart';

import 'package:prop_intel/data/models/lease.dart';
import 'package:prop_intel/data/models/occupancy_status.dart';
import 'package:prop_intel/data/models/property.dart';
import 'package:prop_intel/services/property_status_service.dart';

void main() {
  final service = PropertyStatusService();

  Property property({OccupancyStatus? occupancy}) {
    return Property(
      id: 'p1',
      userId: 'u1',
      propertyAddress: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
      occupancyStatus: occupancy,
    );
  }

  Lease lease({
    DateTime? start,
    DateTime? end,
    double? rent,
  }) {
    return Lease(
      id: 'l1',
      propertyId: 'p1',
      leaseStartDate: start,
      leaseEndDate: end,
      monthlyRent: rent,
    );
  }

  test('returns vacant when manually marked vacant', () {
    final status = service.resolve(
      property: property(occupancy: OccupancyStatus.vacant),
      leases: [lease(end: DateTime(2030, 1, 1), rent: 2000)],
      now: DateTime(2026, 6, 14),
    );

    expect(status.kind, PropertyStatusKind.vacant);
  });

  test('returns no lease on file when there are no leases', () {
    final status = service.resolve(
      property: property(),
      leases: const [],
      now: DateTime(2026, 6, 14),
    );

    expect(status.kind, PropertyStatusKind.noLeaseOnFile);
  });

  test('returns lease ending when end date is within 60 days', () {
    final status = service.resolve(
      property: property(),
      leases: [
        lease(
          start: DateTime(2025, 1, 1),
          end: DateTime(2026, 7, 1),
          rent: 2400,
        ),
      ],
      now: DateTime(2026, 6, 14),
    );

    expect(status.kind, PropertyStatusKind.leaseEnding);
    expect(status.monthlyRent, 2400);
  });

  test('returns rented when lease end date is far out', () {
    final status = service.resolve(
      property: property(),
      leases: [
        lease(
          start: DateTime(2025, 1, 1),
          end: DateTime(2027, 1, 1),
          rent: 1800,
        ),
      ],
      now: DateTime(2026, 6, 14),
    );

    expect(status.kind, PropertyStatusKind.rented);
  });
}
