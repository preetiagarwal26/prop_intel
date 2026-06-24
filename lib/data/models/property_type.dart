enum PropertyType {
  singleFamily('single_family', 'Single family'),
  multiFamily('multi_family', 'Multi-family');

  const PropertyType(this.value, this.label);

  final String value;
  final String label;

  static PropertyType? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final type in PropertyType.values) {
      if (type.value == raw) {
        return type;
      }
    }
    return null;
  }
}
