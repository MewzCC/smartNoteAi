import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/enums/note_priority.dart';
import '../models/note_editor_state.dart';

class NoteEditorController extends Notifier<NoteEditorState> {
  @override
  NoteEditorState build() {
    return const NoteEditorState(
      title: '',
      content: '',
      priority: NotePriority.medium,
      tag: '全部',
      isTask: false,
      done: false,
      isPinned: false,
    );
  }

  void update(NoteEditorState next) {
    state = next;
  }
}

final noteEditorProvider =
    NotifierProvider<NoteEditorController, NoteEditorState>(
      NoteEditorController.new,
    );
