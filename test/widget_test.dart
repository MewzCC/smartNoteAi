import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/main.dart';

void main() {
  test('Note can be serialized and restored', () {
    final note = Note(
      id: 'note-1',
      title: '学习跨平台开发',
      content: '完成智能便签原型',
      createdAt: DateTime(2026, 4, 26, 9),
      reminderAt: DateTime(2026, 4, 26, 20),
      priority: TaskPriority.high,
    );

    final restored = Note.fromJson(note.toJson());

    expect(restored.title, '学习跨平台开发');
    expect(restored.reminderAt, DateTime(2026, 4, 26, 20));
    expect(restored.priority, TaskPriority.high);
  });
}
