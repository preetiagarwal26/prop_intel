enum DocumentType {
  lease('lease', 'Lease'),
  deed('deed', 'Deed'),
  insurance('insurance', 'Insurance'),
  utility('utility', 'Utility Bill'),
  tax('tax', 'Tax Document'),
  hoa('hoa', 'HOA'),
  permit('permit', 'Permit'),
  other('other', 'Other');

  const DocumentType(this.value, this.label);

  final String value;
  final String label;

  static DocumentType fromValue(String? value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.other,
    );
  }
}
