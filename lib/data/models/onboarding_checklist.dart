import 'document_type.dart';

/// Closing-document keys tracked during property onboarding.
enum OnboardingDocKey {
  settlement('settlement', 'Settlement statement'),
  mortgage('mortgage', 'Mortgage closing package'),
  hoa('hoa', 'HOA / condo documents'),
  lease('lease', 'Lease agreement'),
  insurance('insurance', 'Insurance declaration');

  const OnboardingDocKey(this.value, this.label);

  final String value;
  final String label;

  static OnboardingDocKey? forDocumentType(DocumentType type) {
    return switch (type) {
      DocumentType.settlement => OnboardingDocKey.settlement,
      DocumentType.mortgage => OnboardingDocKey.mortgage,
      DocumentType.hoa => OnboardingDocKey.hoa,
      DocumentType.lease => OnboardingDocKey.lease,
      DocumentType.insurance => OnboardingDocKey.insurance,
      _ => null,
    };
  }
}

class OnboardingChecklist {
  const OnboardingChecklist({
    this.expected = const {},
    this.received = const {},
  });

  final Map<String, bool> expected;
  final Map<String, bool> received;

  factory OnboardingChecklist.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const OnboardingChecklist();
    }
    return OnboardingChecklist(
      expected: _boolMap(json['expected']),
      received: _boolMap(json['received']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expected': expected,
      'received': received,
    };
  }

  bool get hasOnboarding =>
      expected.values.any((v) => v) || received.values.any((v) => v);

  List<OnboardingDocKey> get pendingItems {
    return OnboardingDocKey.values.where((key) {
      return expected[key.value] == true && received[key.value] != true;
    }).toList();
  }

  bool get isComplete {
    for (final entry in expected.entries) {
      if (entry.value && received[entry.key] != true) {
        return false;
      }
    }
    return expected.isNotEmpty || received[OnboardingDocKey.settlement.value] == true;
  }

  OnboardingChecklist markReceived(OnboardingDocKey key) {
    final updatedReceived = Map<String, bool>.from(received);
    updatedReceived[key.value] = true;
    return OnboardingChecklist(expected: expected, received: updatedReceived);
  }

  OnboardingChecklist withExpected(Map<String, bool> newExpected) {
    return OnboardingChecklist(
      expected: {...expected, ...newExpected},
      received: received,
    );
  }

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) {
      return {};
    }
    return value.map(
      (key, val) => MapEntry(key.toString(), val == true),
    );
  }
}
