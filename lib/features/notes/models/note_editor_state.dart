import '../../../shared/enums/note_priority.dart';

class NoteEditorState {
  const NoteEditorState({
    required this.title,
    required this.content,
    required this.priority,
    required this.tag,
    required this.isTask,
    required this.done,
    required this.isPinned,
    this.reminderAt,
  });

  final String title;
  final String content;
  final NotePriority priority;
  final String tag;
  final bool isTask;
  final bool done;
  final bool isPinned;
  final DateTime? reminderAt;

  NoteEditorState copyWith({
    String? title,
    String? content,
    NotePriority? priority,
    String? tag,
    bool? isTask,
    bool? done,
    bool? isPinned,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) {
    return NoteEditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      isTask: isTask ?? this.isTask,
      done: done ?? this.done,
      isPinned: isPinned ?? this.isPinned,
      reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
    );
  }
}
