class AddressNormalizer {
  static const _abbreviations = <String, String>{
    'st': 'street',
    'str': 'street',
    'ave': 'avenue',
    'av': 'avenue',
    'blvd': 'boulevard',
    'rd': 'road',
    'dr': 'drive',
    'ln': 'lane',
    'ct': 'court',
    'cir': 'circle',
    'pl': 'place',
    'apt': 'unit',
    'ste': 'unit',
    'unit': 'unit',
    '#': 'unit',
  };

  static String normalize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    var normalized = value.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^\w\s#]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    final tokens = normalized.split(' ').map((token) {
      final cleaned = token.replaceAll('#', '');
      return _abbreviations[cleaned] ?? cleaned;
    }).toList();

    return tokens.join(' ').trim();
  }

  static String fullAddress({
    required String address,
    String? city,
    String? state,
    String? zipCode,
    String? unitNumber,
  }) {
    final parts = <String>[
      if (unitNumber != null && unitNumber.isNotEmpty) 'unit $unitNumber',
      address,
      if (city != null && city.isNotEmpty) city,
      if (state != null && state.isNotEmpty) state,
      if (zipCode != null && zipCode.isNotEmpty) zipCode,
    ];
    return normalize(parts.join(' '));
  }
}
