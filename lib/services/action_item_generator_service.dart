import '../../core/utils/date_parser.dart';
import '../../data/models/action_item.dart';
import '../../data/models/document.dart';
import '../../data/models/document_flag.dart';
import '../../data/models/document_type.dart';
import '../../data/models/property.dart';

class ActionItemGeneratorService {
  static const _leaseWarningDays = 30;
  static const _leaseInfoDays = 90;
  static const _insuranceReminderDays = 15;
  static const _insuranceInfoDays = 30;
  static const _expiryWarningDays = 30;
  static const _dueWarningDays = 7;
  static const _scheduleHorizonMonths = 12;

  List<ActionItemDraft> generate({
    required Property property,
    required Document document,
    required DocumentType documentType,
    required Map<String, dynamic> metadata,
    required List<DocumentFlag> flags,
    DateTime? now,
  }) {
    final drafts = <ActionItemDraft>[];
    final propertyLabel = property.displayAddress;
    final documentId = document.id;
    final propertyId = property.id;
    final today = _dateOnly(now ?? DateTime.now());

    _addDateBasedItems(
      drafts: drafts,
      propertyId: propertyId,
      documentId: documentId,
      propertyLabel: propertyLabel,
      documentType: documentType,
      metadata: metadata,
      today: today,
    );

    if (documentType == DocumentType.lease) {
      _addRentScheduleItems(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        metadata: metadata,
        today: today,
      );
    }

    if (documentType == DocumentType.mortgage) {
      _addMortgageScheduleItems(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        metadata: metadata,
        today: today,
      );
    }

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
    required DateTime today,
  }) {
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

    if (documentType == DocumentType.insurance) {
      _addExpiringItem(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        itemType: 'insurance_expiring',
        titlePrefix: 'Insurance expiring',
        date: DateParser.tryParse(metadata['expiry_date']?.toString()),
        today: today,
        warningDays: _insuranceReminderDays,
        infoDays: _insuranceInfoDays,
        sourceKey: 'doc:$documentId:expiry',
      );
    }

    if (documentType == DocumentType.permit) {
      _addExpiringItem(
        drafts: drafts,
        propertyId: propertyId,
        documentId: documentId,
        propertyLabel: propertyLabel,
        itemType: 'permit_expiring',
        titlePrefix: 'Permit expiring',
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

  void _addRentScheduleItems({
    required List<ActionItemDraft> drafts,
    required String propertyId,
    required String documentId,
    required String propertyLabel,
    required Map<String, dynamic> metadata,
    required DateTime today,
  }) {
    final rent = _parseAmount(metadata['monthly_rent']);
    if (rent == null || rent <= 0) {
      return;
    }

    final dueDay = _parseDay(metadata['rent_due_day']) ?? 1;
    final leaseEnd = DateParser.tryParse(metadata['lease_end_date']?.toString());
    final horizon = _scheduleEnd(today, leaseEnd);

    _addMonthlyItems(
      drafts: drafts,
      propertyId: propertyId,
      documentId: documentId,
      propertyLabel: propertyLabel,
      itemType: 'rent_due',
      titlePrefix: 'Rent due',
      amount: rent,
      dueDay: dueDay,
      today: today,
      horizon: horizon,
      sourcePrefix: 'doc:$documentId:rent',
    );
  }

  void _addMortgageScheduleItems({
    required List<ActionItemDraft> drafts,
    required String propertyId,
    required String documentId,
    required String propertyLabel,
    required Map<String, dynamic> metadata,
    required DateTime today,
  }) {
    final payment = _parseAmount(metadata['monthly_payment']);
    if (payment == null || payment <= 0) {
      return;
    }

    final start = DateParser.tryParse(metadata['loan_start_date']?.toString());
    final termMonths = _parseInt(metadata['loan_term_months']) ?? 360;
    final loanEnd = start != null ? _addMonths(start, termMonths) : null;
    final horizon = _scheduleEnd(today, loanEnd);

    _addMonthlyItems(
      drafts: drafts,
      propertyId: propertyId,
      documentId: documentId,
      propertyLabel: propertyLabel,
      itemType: 'mortgage_due',
      titlePrefix: 'Mortgage payment due',
      amount: payment,
      dueDay: 1,
      today: today,
      horizon: horizon,
      sourcePrefix: 'doc:$documentId:mortgage',
    );
  }

  void _addMonthlyItems({
    required List<ActionItemDraft> drafts,
    required String propertyId,
    required String documentId,
    required String propertyLabel,
    required String itemType,
    required String titlePrefix,
    required double amount,
    required int dueDay,
    required DateTime today,
    required DateTime horizon,
    required String sourcePrefix,
  }) {
    var added = 0;
    var cursor = DateTime(today.year, today.month, 1);
    final formattedAmount = amount.toStringAsFixed(2);

    while (added < _scheduleHorizonMonths) {
      final dueDate = _dueDateForMonth(cursor.year, cursor.month, dueDay);
      if (dueDate.isAfter(horizon)) {
        break;
      }
      if (!dueDate.isBefore(today)) {
        drafts.add(
          ActionItemDraft(
            propertyId: propertyId,
            documentId: documentId,
            itemType: itemType,
            title: '$titlePrefix — $propertyLabel',
            description: '\$$formattedAmount due',
            dueDate: dueDate,
            severity: ActionItemSeverity.info,
            sourceKey:
                '$sourcePrefix:${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}',
          ),
        );
        added++;
      }
      cursor = _addMonths(cursor, 1);
    }
  }

  DateTime _scheduleEnd(DateTime today, DateTime? endDate) {
    final defaultHorizon = _addMonths(today, _scheduleHorizonMonths);
    if (endDate == null) {
      return defaultHorizon;
    }
    return endDate.isBefore(defaultHorizon) ? endDate : defaultHorizon;
  }

  DateTime _dueDateForMonth(int year, int month, int day) {
    final clampedDay = day.clamp(1, 28);
    return DateTime(year, month, clampedDay);
  }

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final day = date.day.clamp(1, 28);
    return DateTime(year, month, day);
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

  double? _parseAmount(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
  }

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  int? _parseDay(dynamic value) => _parseInt(value);

  ActionItemSeverity _severityFromFlag(DocumentFlagSeverity severity) {
    return switch (severity) {
      DocumentFlagSeverity.critical => ActionItemSeverity.critical,
      DocumentFlagSeverity.warning => ActionItemSeverity.warning,
      DocumentFlagSeverity.info => ActionItemSeverity.info,
    };
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDaysAgo(int days) {
    return days == 1 ? '1 day' : '$days days';
  }
}
