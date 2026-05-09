import 'package:flutter/material.dart';

import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/reminder_repeat.dart';
import '../widgets/note_reminder_picker.dart';

export '../widgets/note_reminder_picker.dart' show NoteReminderResult;

class NoteReminderPage extends StatelessWidget {
  const NoteReminderPage({
    super.key,
    this.initialTime,
    this.initialRepeat = ReminderRepeat.none,
  });

  final DateTime? initialTime;
  final ReminderRepeat initialRepeat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: NoteReminderPicker(
                initialTime: initialTime,
                initialRepeat: initialRepeat,
                onFinish: (result) => Navigator.pop(context, result),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
