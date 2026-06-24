import '../data/models/document_type.dart';
import '../data/models/onboarding_checklist.dart';
import '../data/models/onboarding_status.dart';
import '../data/models/property.dart';
import '../data/models/property_type.dart';

class PropertyOnboardingService {
  /// Apply settlement metadata to property profile and start onboarding checklist.
  Property applySettlement({
    required Property property,
    required Map<String, dynamic> metadata,
  }) {
    final expected = <String, bool>{
      if (_bool(metadata['has_mortgage'])) OnboardingDocKey.mortgage.value: true,
      if (_bool(metadata['has_hoa'])) OnboardingDocKey.hoa.value: true,
      if (_bool(metadata['has_renters'])) OnboardingDocKey.lease.value: true,
      if (_bool(metadata['has_insurance']) ||
          _string(metadata['insurance_company']).isNotEmpty)
        OnboardingDocKey.insurance.value: true,
    };

    var checklist = property.onboardingChecklist
        .withExpected(expected)
        .markReceived(OnboardingDocKey.settlement);

    return property.copyWith(
      propertyType: PropertyType.fromJson(_string(metadata['property_type'])) ??
          property.propertyType,
      bedrooms: _int(metadata['bedrooms']) ?? property.bedrooms,
      bathrooms: _double(metadata['bathrooms']) ?? property.bathrooms,
      onboardingStatus: OnboardingStatus.inProgress,
      onboardingChecklist: checklist,
    );
  }

  /// Mark a closing document as received and recompute onboarding status.
  Property applyDocumentSaved({
    required Property property,
    required DocumentType documentType,
  }) {
    final key = OnboardingDocKey.forDocumentType(documentType);
    if (key == null) {
      return property;
    }

    var updated = property.copyWith(
      onboardingChecklist: property.onboardingChecklist.markReceived(key),
    );

    if (updated.onboardingChecklist.isComplete &&
        updated.onboardingStatus == OnboardingStatus.inProgress) {
      updated = updated.copyWith(onboardingStatus: OnboardingStatus.complete);
    } else if (updated.onboardingStatus == OnboardingStatus.none &&
        key != OnboardingDocKey.settlement) {
      updated = updated.copyWith(onboardingStatus: OnboardingStatus.inProgress);
    }

    return updated;
  }

  Property markOnboardingComplete(Property property) {
    return property.copyWith(onboardingStatus: OnboardingStatus.complete);
  }

  bool _bool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1' || value.toLowerCase() == 'yes';
    }
    if (value is num) {
      return value != 0;
    }
    return false;
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  int? _int(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  double? _double(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
