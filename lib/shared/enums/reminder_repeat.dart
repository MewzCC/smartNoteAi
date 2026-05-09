enum ReminderRepeat {
  none('不重复'),
  daily('每天'),
  weekly('每周'),
  monthly('每月');

  const ReminderRepeat(this.label);

  final String label;

  static ReminderRepeat fromLabel(String label) {
    return values.firstWhere(
      (item) => item.label == label,
      orElse: () => none,
    );
  }
}