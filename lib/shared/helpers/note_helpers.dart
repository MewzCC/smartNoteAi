import '../../data/models/note_model.dart';
import '../../shared/enums/note_priority.dart';

List<NoteModel> sortedVisibleNotes(List<NoteModel> notes) =>
    [...notes.where((note) => !note.isArchived)]..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      if (a.done != b.done) return a.done ? 1 : -1;
      return b.createdAt.compareTo(a.createdAt);
    });

NotePriority priorityForIndex(int index) {
  return switch (index % 3) {
    0 => NotePriority.medium,
    1 => NotePriority.low,
    _ => NotePriority.high,
  };
}
