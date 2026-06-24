enum OnboardingStatus {
  none('none'),
  inProgress('in_progress'),
  complete('complete');

  const OnboardingStatus(this.value);

  final String value;

  static OnboardingStatus fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return OnboardingStatus.none;
    }
    for (final status in OnboardingStatus.values) {
      if (status.value == raw) {
        return status;
      }
    }
    return OnboardingStatus.none;
  }
}
