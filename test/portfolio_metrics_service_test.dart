import 'package:flutter_test/flutter_test.dart';

import 'package:prop_intel/data/models/lease.dart';
import 'package:prop_intel/data/models/property.dart';
import 'package:prop_intel/data/repositories/supabase_repository.dart';
import 'package:prop_intel/services/portfolio_metrics_service.dart';
import 'package:prop_intel/services/property_status_service.dart';

void main() {
  final metricsService = PortfolioMetricsService(PropertyStatusService());

  Property property(String id) {
    return Property(
      id: id,
      userId: 'u1',
      propertyAddress: '$id Main',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
    );
  }

  test('computes portfolio metrics from entries', () {
    final entries = [
      PortfolioEntry(
        property: property('p1'),
        leases: [
          Lease(
            id: 'l1',
            propertyId: 'p1',
            leaseEndDate: DateTime(2026, 6, 30),
            monthlyRent: 2000,
          ),
        ],
        documents: const [],
      ),
      PortfolioEntry(
        property: property('p2'),
        leases: [
          Lease(
            id: 'l2',
            propertyId: 'p2',
            leaseEndDate: DateTime(2027, 1, 1),
            monthlyRent: 1500,
          ),
        ],
        documents: const [],
      ),
    ];

    final metrics = metricsService.compute(
      entries: entries,
      openActionItems: const [],
      now: DateTime(2026, 6, 14),
    );

    expect(metrics.propertyCount, 2);
    expect(metrics.documentCount, 0);
    expect(metrics.leasesExpiringWithin30Days, 1);
    expect(metrics.monthlyRentTotal, 3500);
  });
}
