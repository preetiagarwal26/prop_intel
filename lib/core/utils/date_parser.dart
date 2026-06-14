class DateParser {
  static DateTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final slashMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$')
        .firstMatch(trimmed);
    if (slashMatch != null) {
      final month = int.parse(slashMatch.group(1)!);
      final day = int.parse(slashMatch.group(2)!);
      var year = int.parse(slashMatch.group(3)!);
      if (year < 100) {
        year += 2000;
      }
      return DateTime(year, month, day);
    }

    return null;
  }

  static String? toIsoDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    return date.toIso8601String().split('T').first;
  }
}
