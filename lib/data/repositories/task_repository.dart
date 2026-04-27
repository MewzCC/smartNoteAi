import '../models/note_model.dart';

class TaskRepository {
  List<NoteModel> today(List<NoteModel> notes) => notes.take(2).toList();
  List<NoteModel> week(List<NoteModel> notes) => notes.skip(2).take(2).toList();
  List<NoteModel> month(List<NoteModel> notes) =>
      notes.where((note) => !note.done).skip(1).take(3).toList();
  List<NoteModel> done(List<NoteModel> notes) =>
      notes.where((note) => note.done).toList();
}
