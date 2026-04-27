import 'note_model.dart';

class ArchiveModel {
  const ArchiveModel({required this.date, required this.notes});

  final DateTime date;
  final List<NoteModel> notes;
}
