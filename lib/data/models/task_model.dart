class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.remindTime,
    this.done = false,
  });

  final String id;
  final String title;
  final DateTime? remindTime;
  final bool done;
}
