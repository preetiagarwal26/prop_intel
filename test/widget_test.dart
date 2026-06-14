import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_portfolio/core/utils/address_normalizer.dart';
import 'package:real_estate_portfolio/services/property_matching_service.dart';
import 'package:real_estate_portfolio/data/models/lease_extraction.dart';
import 'package:real_estate_portfolio/data/models/property.dart';
import 'package:real_estate_portfolio/services/pdf_extraction_service.dart';

void main() {
  test('address normalizer standardizes abbreviations', () {
    expect(
      AddressNormalizer.normalize('123 Main St, Apt 4'),
      '123 main street unit 4',
    );
  });

  test('property matcher finds exact normalized match', () {
    const extraction = LeaseExtraction(
      propertyAddress: '123 Main Street',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
      unitNumber: '4',
    );

    final properties = [
      Property(
        id: 'p1',
        userId: 'u1',
        propertyAddress: '123 Main St',
        city: 'Austin',
        state: 'TX',
        zipCode: '78701',
        unitNumber: '4',
        normalizedAddress: '123 main street',
      ),
    ];

    final result = PropertyMatchingService().findMatch(extraction, properties);

    expect(result.isNewProperty, isFalse);
    expect(result.property?.id, 'p1');
    expect(result.confidence, 1.0);
  });

  test('pdf extraction reads sample lease', () async {
    final bytes = await File('samples/sample_lease.pdf').readAsBytes();
    final text = await PdfExtractionService().extractText(bytes);

    expect(text, contains('742 Evergreen Terrace'));
    expect(text, contains('Springfield'));
    expect(text, contains('1850.00'));
  });
}
