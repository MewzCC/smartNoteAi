import '../../shared/enums/note_color.dart';
import '../../shared/enums/note_priority.dart';
import '../../shared/enums/reminder_repeat.dart';

class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.reminderAt,
    this.reminderRepeat = ReminderRepeat.none,
    this.done = false,
    this.priority = NotePriority.medium,
    this.paperColor = NoteColor.yellow,
    this.isTask = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
    this.tag = '全部',
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? reminderAt;
  final ReminderRepeat reminderRepeat;
  final bool done;
  final NotePriority priority;
  final NoteColor paperColor;
  final bool isTask;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String tag;

  NoteModel copyWith({
    String? title,
    String? content,
    DateTime? reminderAt,
    ReminderRepeat? reminderRepeat,
    bool clearReminder = false,
    bool? done,
    NotePriority? priority,
    NoteColor? paperColor,
    bool? isTask,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? tag,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
      reminderRepeat: clearReminder ? ReminderRepeat.none : (reminderRepeat ?? this.reminderRepeat),
      done: done ?? this.done,
      priority: priority ?? this.priority,
      paperColor: paperColor ?? this.paperColor,
      isTask: isTask ?? this.isTask,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      tag: tag ?? this.tag,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'reminderRepeat': reminderRepeat.name,
    'done': done,
    'priority': priority.name,
    'paperColor': paperColor.name,
    'isTask': isTask,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'isDeleted': isDeleted,
    'deletedAt': deletedAt?.toIso8601String(),
    'tag': tag,
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final priority = NotePriority.values.firstWhere(
      (item) => item.name == json['priority'],
      orElse: () => NotePriority.medium,
    );
    final reminderRepeat = ReminderRepeat.values.firstWhere(
      (item) => item.name == json['reminderRepeat'],
      orElse: () => ReminderRepeat.none,
    );
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.parse(json['reminderAt'] as String),
      reminderRepeat: reminderRepeat,
      done: json['done'] as bool? ?? false,
      priority: priority,
      paperColor: NoteColor.values.firstWhere(
        (item) => item.name == json['paperColor'],
        orElse: () => noteColorFromPriority(priority),
      ),
      isTask: json['isTask'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      tag: json['tag'] as String? ?? '全部',
    );
  }
}
