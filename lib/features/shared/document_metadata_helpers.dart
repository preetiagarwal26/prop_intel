import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/document_flag.dart';
import '../../data/models/document_type.dart';

/// Known metadata field keys per document type for review/edit UI.
const documentMetadataFieldLabels = {
  DocumentType.settlement: {
    'property_type': 'Property type (single_family or multi_family)',
    'bedrooms': 'Bedrooms',
    'bathrooms': 'Bathrooms',
    'has_mortgage': 'Has mortgage (true/false)',
    'has_hoa': 'Has HOA (true/false)',
    'has_renters': 'Has renters (true/false)',
    'has_insurance': 'Has insurance (true/false)',
    'insurance_company': 'Insurance company',
  },
  DocumentType.mortgage: {
    'monthly_payment': 'Monthly payment',
    'loan_start_date': 'Loan start date',
    'loan_term_months': 'Loan term (months)',
    'lender_name': 'Lender name',
  },
  DocumentType.lease: {
    'lease_start_date': 'Lease start date',
    'lease_end_date': 'Lease end date',
    'monthly_rent': 'Monthly rent',
    'rent_due_day': 'Rent due day of month (1-28)',
    'security_deposit': 'Security deposit',
    'late_fee': 'Late fee',
    'landlord_name': 'Landlord name',
    'tenant_names': 'Tenant names (comma-separated)',
    'tenant_contact': 'Tenant contact (phone/email)',
  },
  DocumentType.deed: {
    'grantor': 'Grantor',
    'grantee': 'Grantee',
    'recording_date': 'Recording date',
    'parcel_number': 'Parcel number',
  },
  DocumentType.insurance: {
    'carrier': 'Insurance carrier',
    'policy_number': 'Policy number',
    'policy_start_date': 'Policy start date',
    'expiry_date': 'Expiry date',
    'coverage_amount': 'Coverage amount',
  },
  DocumentType.utility: {
    'provider': 'Utility provider',
    'account_number': 'Account number',
    'amount_due': 'Amount due',
    'due_date': 'Due date',
    'service_address': 'Service address',
  },
  DocumentType.tax: {
    'tax_year': 'Tax year',
    'amount_due': 'Amount due',
    'due_date': 'Due date',
    'parcel_number': 'Parcel number',
  },
  DocumentType.hoa: {
    'association_name': 'HOA name',
    'amount_due': 'Amount due',
    'due_date': 'Due date',
  },
  DocumentType.permit: {
    'permit_type': 'Permit type',
    'permit_number': 'Permit number',
    'expiry_date': 'Expiry date',
    'issuing_authority': 'Issuing authority',
  },
  DocumentType.other: {
    'notes': 'Notes',
  },
};

Map<String, String> metadataFieldsForType(DocumentType type) {
  return documentMetadataFieldLabels[type] ??
      documentMetadataFieldLabels[DocumentType.other]!;
}

String formatMetadataKey(String key) {
  return key
      .split('_')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String metadataValueAsString(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is List) {
    return value.map((e) => e.toString()).join(', ');
  }
  return value.toString();
}

dynamic metadataValueFromString(String key, String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (key == 'tenant_names') {
    return trimmed
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
  return trimmed;
}

Color flagSeverityColor(DocumentFlagSeverity severity) {
  return switch (severity) {
    DocumentFlagSeverity.info => AppColors.success,
    DocumentFlagSeverity.warning => AppColors.warn,
    DocumentFlagSeverity.critical => AppColors.danger,
  };
}

Color flagSeverityBackground(DocumentFlagSeverity severity) {
  return switch (severity) {
    DocumentFlagSeverity.info => AppColors.successBg,
    DocumentFlagSeverity.warning => AppColors.warnBg,
    DocumentFlagSeverity.critical => AppColors.dangerBg,
  };
}
