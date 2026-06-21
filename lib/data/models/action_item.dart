enum ActionItemSeverity {
  info('info'),
  warning('warning'),
  critical('critical');

  const ActionItemSeverity(this.value);

  final String value;

  static ActionItemSeverity fromValue(String? value) {
    return ActionItemSeverity.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ActionItemSeverity.info,
    );
  }

  int get sortOrder => switch (this) {
        ActionItemSeverity.critical => 0,
        ActionItemSeverity.warning => 1,
        ActionItemSeverity.info => 2,
      };
}

enum ActionItemStatus {
  open('open'),
  done('done'),
  dismissed('dismissed');

  const ActionItemStatus(this.value);

  final String value;

  static ActionItemStatus fromValue(String? value) {
    return ActionItemStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ActionItemStatus.open,
    );
  }
}

class ActionItem {
  const ActionItem({
    required this.id,
    required this.userId,
    this.propertyId,
    this.documentId,
    required this.itemType,
    required this.title,
    this.description,
    this.dueDate,
    required this.severity,
    required this.status,
    required this.sourceKey,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? propertyId;
  final String? documentId;
  final String itemType;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final ActionItemSeverity severity;
  final ActionItemStatus status;
  final String sourceKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      propertyId: json['property_id'] as String?,
      documentId: json['document_id'] as String?,
      itemType: json['item_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      severity: ActionItemSeverity.fromValue(json['severity'] as String?),
      status: ActionItemStatus.fromValue(json['status'] as String?),
      sourceKey: json['source_key'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'property_id': propertyId,
      'document_id': documentId,
      'item_type': itemType,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'severity': severity.value,
      'status': status.value,
      'source_key': sourceKey,
    };
  }

  ActionItem copyWithStatus(ActionItemStatus status) {
    return ActionItem(
      id: id,
      userId: userId,
      propertyId: propertyId,
      documentId: documentId,
      itemType: itemType,
      title: title,
      description: description,
      dueDate: dueDate,
      severity: severity,
      status: status,
      sourceKey: sourceKey,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Draft used when generating items before insert (no id yet).
class ActionItemDraft {
  const ActionItemDraft({
    required this.propertyId,
    required this.documentId,
    required this.itemType,
    required this.title,
    this.description,
    this.dueDate,
    required this.severity,
    required this.sourceKey,
  });

  final String propertyId;
  final String documentId;
  final String itemType;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final ActionItemSeverity severity;
  final String sourceKey;
}
