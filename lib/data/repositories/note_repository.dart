import 'package:uuid/uuid.dart';

import '../../core/constants/hive_keys.dart';
import '../../shared/enums/note_priority.dart';
import '../local/hive_boxes.dart';
import '../models/note_model.dart';

class NoteRepository {
  final _uuid = const Uuid();

  List<NoteModel> loadNotes() {
    final raw = HiveBoxes.notes.get(HiveKeys.notesList);
    if (raw is! List) return [];
    final notes = raw
        .whereType<Map>()
        .map((item) => NoteModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final active = _purgeExpiredTrash(notes);
    if (active.length != notes.length) {
      saveNotes(active);
    }
    return active;
  }

  Future<void> saveNotes(List<NoteModel> notes) {
    return HiveBoxes.notes.put(
      HiveKeys.notesList,
      notes.map((note) => note.toJson()).toList(),
    );
  }

  NoteModel create({
    required String title,
    required String content,
    DateTime? reminderAt,
    NotePriority priority = NotePriority.medium,
    String tag = '全部',
    bool isTask = false,
  }) {
    return NoteModel(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      reminderAt: reminderAt,
      priority: priority,
      tag: tag,
      isTask: isTask,
    );
  }

  List<NoteModel> _purgeExpiredTrash(List<NoteModel> notes) {
    final now = DateTime.now();
    return notes.where((note) {
      if (!note.isDeleted) return true;
      final deletedAt = note.deletedAt;
      if (deletedAt == null) return false;
      return now.difference(deletedAt) < const Duration(days: 14);
    }).toList();
  }
}
