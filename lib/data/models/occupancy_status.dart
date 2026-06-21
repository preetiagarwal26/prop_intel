enum OccupancyStatus {
  rented('rented'),
  vacant('vacant');

  const OccupancyStatus(this.value);

  final String value;

  static OccupancyStatus? fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final status in OccupancyStatus.values) {
      if (status.value == raw) {
        return status;
      }
    }
    return null;
  }

  String get label => switch (this) {
        OccupancyStatus.rented => 'Mark as rented',
        OccupancyStatus.vacant => 'Mark as vacant',
      };
}
