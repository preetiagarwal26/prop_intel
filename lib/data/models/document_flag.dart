enum DocumentFlagSeverity {
  info('info'),
  warning('warning'),
  critical('critical');

  const DocumentFlagSeverity(this.value);

  final String value;

  static DocumentFlagSeverity fromValue(String? value) {
    return DocumentFlagSeverity.values.firstWhere(
      (s) => s.value == value,
      orElse: () => DocumentFlagSeverity.warning,
    );
  }
}

class DocumentFlag {
  const DocumentFlag({
    required this.severity,
    required this.title,
    required this.description,
  });

  final DocumentFlagSeverity severity;
  final String title;
  final String description;

  factory DocumentFlag.fromJson(Map<String, dynamic> json) {
    return DocumentFlag(
      severity: DocumentFlagSeverity.fromValue(json['severity'] as String?),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.value,
      'title': title,
      'description': description,
    };
  }
}
