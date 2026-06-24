import 'package:flutter_test/flutter_test.dart';
import 'package:prop_intel/data/models/document.dart';
import 'package:prop_intel/data/models/document_flag.dart';
import 'package:prop_intel/data/models/document_type.dart';
import 'package:prop_intel/data/models/property.dart';
import 'package:prop_intel/services/action_item_generator_service.dart';

void main() {
  test('generates lease expiring action item within 30 days', () {
    final endDate = DateTime.now().add(const Duration(days: 14));
    final endDateStr =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    const property = Property(
      id: 'p1',
      userId: 'u1',
      propertyAddress: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
    );

    const document = Document(
      id: 'd1',
      fileName: 'lease.pdf',
      storagePath: 'path/lease.pdf',
      documentType: DocumentType.lease,
    );

    final drafts = ActionItemGeneratorService().generate(
      property: property,
      document: document,
      documentType: DocumentType.lease,
      metadata: {'lease_end_date': endDateStr},
      flags: const [],
    );

    expect(drafts, isNotEmpty);
    expect(drafts.first.itemType, 'lease_expiring');
    expect(drafts.first.severity.value, 'critical');
  });

  test('generates action items from AI flags', () {
    const property = Property(
      id: 'p1',
      userId: 'u1',
      propertyAddress: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
    );

    const document = Document(
      id: 'd1',
      fileName: 'lease.pdf',
      storagePath: 'path/lease.pdf',
    );

    final drafts = ActionItemGeneratorService().generate(
      property: property,
      document: document,
      documentType: DocumentType.lease,
      metadata: const {},
      flags: const [
        DocumentFlag(
          severity: DocumentFlagSeverity.warning,
          title: 'Subletting allowed without consent',
          description: 'Review clause 4.2',
        ),
      ],
    );

    expect(drafts, hasLength(1));
    expect(drafts.first.itemType, 'ai_flag');
    expect(drafts.first.title, 'Subletting allowed without consent');
  });

  test('generates rent due schedule for lease', () {
    final today = DateTime(2026, 6, 14);
    const property = Property(
      id: 'p1',
      userId: 'u1',
      propertyAddress: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
    );

    const document = Document(
      id: 'd1',
      fileName: 'lease.pdf',
      storagePath: 'path/lease.pdf',
    );

    final drafts = ActionItemGeneratorService().generate(
      property: property,
      document: document,
      documentType: DocumentType.lease,
      metadata: const {
        'monthly_rent': 2000,
        'rent_due_day': 1,
        'lease_end_date': '2027-06-01',
      },
      flags: const [],
      now: today,
    );

    expect(drafts.any((d) => d.itemType == 'rent_due'), isTrue);
  });

  test('generates mortgage payment schedule', () {
    final today = DateTime(2026, 6, 14);
    const property = Property(
      id: 'p1',
      userId: 'u1',
      propertyAddress: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
    );

    const document = Document(
      id: 'd2',
      fileName: 'mortgage.pdf',
      storagePath: 'path/mortgage.pdf',
    );

    final drafts = ActionItemGeneratorService().generate(
      property: property,
      document: document,
      documentType: DocumentType.mortgage,
      metadata: const {
        'monthly_payment': 1500,
        'loan_start_date': '2020-01-01',
        'loan_term_months': 360,
      },
      flags: const [],
      now: today,
    );

    expect(drafts.any((d) => d.itemType == 'mortgage_due'), isTrue);
  });
}
