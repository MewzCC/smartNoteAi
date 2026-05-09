import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_dialog.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/helpers/checklist_helper.dart';
import '../provider/home_provider.dart';

class TodayTaskSection extends ConsumerWidget {
  const TodayTaskSection({super.key, required this.notes});

  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    final tasks =
        notes
            .where(
              (note) =>
                  note.isTask &&
                  !note.done &&
                  note.reminderAt != null &&
                  dateOnly(note.reminderAt!).isAtSameMomentAs(today),
            )
            .toList()
          ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
    final shownTasks = tasks.take(3).toList();
    if (tasks.isEmpty) {
      return const EmptyState(
        text: '暂无今日任务',
        icon: Icons.check_box_outlined,
        height: 76,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final note in shownTasks)
            Builder(
              builder: (context) {
                final canComplete = canCompleteTaskContent(note.content);
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: note.done,
                  onChanged: (_) => _handleTaskTap(
                    context: context,
                    ref: ref,
                    note: note,
                    canComplete: canComplete,
                  ),
                  title: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: note.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: canComplete ? null : const Text('完成所有待办后可标记完成'),
                  secondary: Text(
                    note.reminderAt == null
                        ? ''
                        : '${note.reminderAt!.hour.toString().padLeft(2, '0')}:${note.reminderAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handleTaskTap({
    required BuildContext context,
    required WidgetRef ref,
    required NoteModel note,
    required bool canComplete,
  }) async {
    if (!canComplete) {
      ToastUtils.show('完成所有待办后才可以标记完成');
      return;
    }

    final ok = await StickyDialog.confirmCompleteTask(context, note.title);
    if (!ok || !context.mounted) return;
    await ref.read(smartNoteProvider.notifier).toggleDone(note.id);
  }
}
