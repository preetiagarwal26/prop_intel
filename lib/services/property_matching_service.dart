import 'package:string_similarity/string_similarity.dart';

import '../core/utils/address_normalizer.dart';
import '../data/models/lease_extraction.dart';
import '../data/models/lease_upload_draft.dart';
import '../data/models/property.dart';

class PropertyMatchingService {
  static const double fuzzyThreshold = 0.85;

  PropertyMatchResult findMatch(
    LeaseExtraction extraction,
    List<Property> properties,
  ) {
    if (properties.isEmpty) {
      return PropertyMatchResult.noMatch();
    }

    final normalizedInput = AddressNormalizer.normalize(extraction.propertyAddress);
    final inputCity = extraction.city.toLowerCase().trim();
    final inputState = extraction.state.toLowerCase().trim();
    final inputZip = extraction.zipCode.trim();
    final inputUnit = extraction.unitNumber.toLowerCase().trim();

    Property? exactMatch;
    for (final property in properties) {
      final normalizedExisting =
          property.normalizedAddress ?? AddressNormalizer.normalize(property.propertyAddress);

      final sameAddress = normalizedExisting == normalizedInput && normalizedInput.isNotEmpty;
      final sameCity = property.city.toLowerCase().trim() == inputCity;
      final sameState = property.state.toLowerCase().trim() == inputState;
      final sameZip = property.zipCode.trim() == inputZip;
      final sameUnit = (property.unitNumber ?? '').toLowerCase().trim() == inputUnit;

      if (sameAddress && sameCity && sameState && sameZip && (inputUnit.isEmpty || sameUnit)) {
        exactMatch = property;
        break;
      }
    }

    if (exactMatch != null) {
      return PropertyMatchResult(
        property: exactMatch,
        confidence: 1.0,
        matchType: PropertyMatchType.exact,
        isNewProperty: false,
      );
    }

    Property? locationMatch;
    double locationScore = 0;
    for (final property in properties) {
      final sameCity = property.city.toLowerCase().trim() == inputCity;
      final sameState = property.state.toLowerCase().trim() == inputState;
      final sameZip = property.zipCode.trim() == inputZip;

      if (!sameCity || !sameState || !sameZip) {
        continue;
      }

      final score = StringSimilarity.compareTwoStrings(
        AddressNormalizer.normalize(property.propertyAddress),
        normalizedInput,
      );

      if (score > locationScore) {
        locationScore = score;
        locationMatch = property;
      }
    }

    if (locationMatch != null && locationScore >= fuzzyThreshold) {
      return PropertyMatchResult(
        property: locationMatch,
        confidence: locationScore,
        matchType: PropertyMatchType.location,
        isNewProperty: false,
      );
    }

    Property? fuzzyMatch;
    double fuzzyScore = 0;
    for (final property in properties) {
      final candidate = AddressNormalizer.fullAddress(
        address: property.propertyAddress,
        city: property.city,
        state: property.state,
        zipCode: property.zipCode,
        unitNumber: property.unitNumber,
      );
      final target = AddressNormalizer.fullAddress(
        address: extraction.propertyAddress,
        city: extraction.city,
        state: extraction.state,
        zipCode: extraction.zipCode,
        unitNumber: extraction.unitNumber,
      );

      final score = StringSimilarity.compareTwoStrings(candidate, target);
      if (score > fuzzyScore) {
        fuzzyScore = score;
        fuzzyMatch = property;
      }
    }

    if (fuzzyMatch != null && fuzzyScore >= fuzzyThreshold) {
      return PropertyMatchResult(
        property: fuzzyMatch,
        confidence: fuzzyScore,
        matchType: PropertyMatchType.fuzzy,
        isNewProperty: false,
      );
    }

    return PropertyMatchResult.noMatch();
  }
}
