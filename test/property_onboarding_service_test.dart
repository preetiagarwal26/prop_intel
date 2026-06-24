import 'package:flutter_test/flutter_test.dart';

import 'package:prop_intel/data/models/document_type.dart';
import 'package:prop_intel/data/models/onboarding_status.dart';
import 'package:prop_intel/data/models/property.dart';
import 'package:prop_intel/services/property_onboarding_service.dart';

void main() {
  final service = PropertyOnboardingService();

  Property baseProperty() {
    return const Property(
      id: 'p1',
      userId: 'u1',
      propertyAddress: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
    );
  }

  test('settlement sets profile and expected closing documents', () {
    final updated = service.applySettlement(
      property: baseProperty(),
      metadata: {
        'property_type': 'single_family',
        'bedrooms': 3,
        'bathrooms': 2,
        'has_mortgage': true,
        'has_hoa': true,
        'has_renters': true,
        'has_insurance': true,
      },
    );

    expect(updated.onboardingStatus, OnboardingStatus.inProgress);
    expect(updated.bedrooms, 3);
    expect(updated.onboardingChecklist.received['settlement'], isTrue);
    expect(updated.onboardingChecklist.expected['mortgage'], isTrue);
    expect(updated.onboardingChecklist.expected['lease'], isTrue);
    expect(updated.onboardingChecklist.pendingItems.length, 4);
  });

  test('marking expected documents received completes onboarding', () {
    var property = service.applySettlement(
      property: baseProperty(),
      metadata: const {'has_mortgage': true},
    );

    property = service.applyDocumentSaved(
      property: property,
      documentType: DocumentType.mortgage,
    );

    expect(property.onboardingChecklist.isComplete, isTrue);
    expect(property.onboardingStatus, OnboardingStatus.complete);
  });
}
