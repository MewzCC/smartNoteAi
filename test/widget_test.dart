import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note_ai/data/models/note_model.dart';
import 'package:smart_note_ai/shared/enums/note_priority.dart';

void main() {
  test('便签可以序列化并恢复', () {
    final note = NoteModel(
      id: 'note-1',
      title: '学习跨平台开发',
      content: '完成智能便签原型',
      createdAt: DateTime(2026, 4, 26, 9),
      reminderAt: DateTime(2026, 4, 26, 20),
      priority: NotePriority.high,
    );

    final restored = NoteModel.fromJson(note.toJson());

    expect(restored.title, '学习跨平台开发');
    expect(restored.reminderAt, DateTime(2026, 4, 26, 20));
    expect(restored.priority, NotePriority.high);
  });
}
