import '../../core/utils/date_parser.dart';
import '../../data/models/action_item.dart';
import '../../data/models/document.dart';
import '../../data/models/document_flag.dart';
import '../../data/models/document_type.dart';
import '../../data/models/property.dart';

class ActionItemGeneratorService {
  static const _leaseWarningDays = 30;
  static const _leaseInfoDays = 90;
  static const _expiryWarningDays = 30;
  static const _dueWarningDays = 7;

  List<ActionItemDraft> generate({
    required Property property,
    required Document document,
    required DocumentType documentType,
    required Map<String, dynamic> metadata,
    required List<DocumentFlag> flags,
  }) {
    final drafts = <ActionItemDraft>[];
    final propertyLabel = property.displayAddress;
    final documentId = document.id;
    final propertyId = property.id;

    _addDateBasedItems(
      drafts: drafts,
      propertyId: propertyId,
      documentId: documentId,
      propertyLabel: propertyLabel,
      documentType: documentType,
      metadata: metadata,
    );

    for (var i = 0; i < flags.length; i++) {
      final flag = flags[i];
      if (flag.title.trim().isEmpty) {
        continue;
      }
      drafts.add(
        ActionItemDraft(
          propertyId: propertyId,
          documentId: documentId,
          itemType: 'ai_flag',
          title: flag.title,
          description: flag.description.isEmpty ? null : flag.description,
          severity: _severityFromFlag(flag.severity),
          sourceKey: 'doc:$documentId:flag:$i',
        ),
      );
    }

    return drafts;
  }

  void _addDateBasedItems({
    required List<ActionItemDraft> drafts,
    required String propertyId,
    required String documentId,
    required String propertyLabel,
    required DocumentType documentType,
    required Map<String, dynamic> metadata,
  }) {
    final today = _dateOnly(DateTime.now());

    if (documentType == DocumentType.lease) {
      _addExpiringItem(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        itemType: 'lease_expiring',
        titlePrefix: 'Lease expiring',
        date: DateParser.tryParse(metadata['lease_end_date']?.toString()),
        today: today,
        warningDays: _leaseWarningDays,
        infoDays: _leaseInfoDays,
        sourceKey: 'doc:$documentId:lease_end',
      );
    }

    if (documentType == DocumentType.insurance ||
        documentType == DocumentType.permit) {
      _addExpiringItem(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        itemType: documentType == DocumentType.insurance
            ? 'insurance_expiring'
            : 'permit_expiring',
        titlePrefix: documentType == DocumentType.insurance
            ? 'Insurance expiring'
            : 'Permit expiring',
        date: DateParser.tryParse(metadata['expiry_date']?.toString()),
        today: today,
        warningDays: _expiryWarningDays,
        infoDays: _expiryWarningDays,
        sourceKey: 'doc:$documentId:expiry',
      );
    }

    if (documentType == DocumentType.utility ||
        documentType == DocumentType.tax ||
        documentType == DocumentType.hoa) {
      _addDueItem(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        itemType: '${documentType.value}_due',
        titlePrefix: switch (documentType) {
          DocumentType.utility => 'Utility bill due',
          DocumentType.tax => 'Tax payment due',
          DocumentType.hoa => 'HOA payment due',
          _ => 'Payment due',
        },
        date: DateParser.tryParse(metadata['due_date']?.toString()),
        today: today,
        sourceKey: 'doc:$documentId:due',
      );
    }
  }

  void _addExpiringItem({
    required List<ActionItemDraft> drafts,
    required String propertyId,
    required String documentId,
    required String propertyLabel,
    required String itemType,
    required String titlePrefix,
    required DateTime? date,
    required DateTime today,
    required int warningDays,
    required int infoDays,
    required String sourceKey,
  }) {
    if (date == null) {
      return;
    }

    final due = _dateOnly(date);
    final daysUntil = due.difference(today).inDays;

    if (daysUntil < 0) {
      drafts.add(
        ActionItemDraft(
          propertyId: propertyId,
          documentId: documentId,
          itemType: itemType,
          title: '$titlePrefix — $propertyLabel',
          description: 'Expired ${_formatDaysAgo(-daysUntil)} ago.',
          dueDate: due,
          severity: ActionItemSeverity.critical,
          sourceKey: sourceKey,
        ),
      );
      return;
    }

    if (daysUntil <= warningDays) {
      drafts.add(
        ActionItemDraft(
          propertyId: propertyId,
          documentId: documentId,
          itemType: itemType,
          title: '$titlePrefix — $propertyLabel',
          description: 'Expires in $daysUntil day(s).',
          dueDate: due,
          severity: daysUntil <= 14
              ? ActionItemSeverity.critical
              : ActionItemSeverity.warning,
          sourceKey: sourceKey,
        ),
      );
      return;
    }

    if (daysUntil <= infoDays) {
      drafts.add(
        ActionItemDraft(
          propertyId: propertyId,
          documentId: documentId,
          itemType: itemType,
          title: '$titlePrefix — $propertyLabel',
          description: 'Expires in $daysUntil day(s).',
          dueDate: due,
          severity: ActionItemSeverity.info,
          sourceKey: sourceKey,
        ),
      );
    }
  }

  void _addDueItem({
    required List<ActionItemDraft> drafts,
    required String propertyId,
    required String documentId,
    required String propertyLabel,
    required String itemType,
    required String titlePrefix,
    required DateTime? date,
    required DateTime today,
    required String sourceKey,
  }) {
    if (date == null) {
      return;
    }

    final due = _dateOnly(date);
    final daysUntil = due.difference(today).inDays;

    if (daysUntil < 0) {
      drafts.add(
        ActionItemDraft(
          propertyId: propertyId,
          documentId: documentId,
          itemType: itemType,
          title: '$titlePrefix — $propertyLabel',
          description: 'Overdue by ${-daysUntil} day(s).',
          dueDate: due,
          severity: ActionItemSeverity.critical,
          sourceKey: sourceKey,
        ),
      );
      return;
    }

    if (daysUntil <= _dueWarningDays) {
      drafts.add(
        ActionItemDraft(
          propertyId: propertyId,
          documentId: documentId,
          itemType: itemType,
          title: '$titlePrefix — $propertyLabel',
          description: daysUntil == 0
              ? 'Due today.'
              : 'Due in $daysUntil day(s).',
          dueDate: due,
          severity: daysUntil == 0
              ? ActionItemSeverity.critical
              : ActionItemSeverity.warning,
          sourceKey: sourceKey,
        ),
      );
    }
  }

  ActionItemSeverity _severityFromFlag(DocumentFlagSeverity severity) {
    return switch (severity) {
      DocumentFlagSeverity.critical => ActionItemSeverity.critical,
      DocumentFlagSeverity.warning => ActionItemSeverity.warning,
      DocumentFlagSeverity.info => ActionItemSeverity.info,
    };
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDaysAgo(int days) {
    return days == 1 ? '1 day' : '$days days';
  }
}
