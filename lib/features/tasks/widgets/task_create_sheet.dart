import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_input.dart';
import '../../../shared/enums/note_color.dart';
import '../../notes/pages/note_reminder_page.dart';
import '../provider/task_provider.dart';

class TaskCreateSheet extends ConsumerStatefulWidget {
  const TaskCreateSheet({super.key});

  @override
  ConsumerState<TaskCreateSheet> createState() => _TaskCreateSheetState();
}

class _TaskCreateSheetState extends ConsumerState<TaskCreateSheet> {
  late final TextEditingController _todoController;
  DateTime? _reminderAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _todoController = TextEditingController();
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '新建待办',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StickyInput(
                      controller: _todoController,
                      hint: '填写待办内容',
                      icon: Icons.check_circle_outline_rounded,
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _TaskReminderField(
                      reminderAt: _reminderAt,
                      onTap: _pickReminder,
                      onClear: _reminderAt == null
                          ? null
                          : () => setState(() => _reminderAt = null),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveTask,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_task_rounded),
                            label: const Text('保存待办'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    final result = await Navigator.of(context).push<NoteReminderResult>(
      buildAppPageRoute(
        child: NoteReminderPage(initialTime: _reminderAt),
        axis: AxisDirection.up,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _reminderAt = result.enabled ? result.time : null);
  }

  Future<void> _saveTask() async {
    final content = _todoController.text.trim();
    if (content.isEmpty) {
      ToastUtils.show('请输入待办内容');
      return;
    }

    setState(() => _saving = true);
    await ref
        .read(smartNoteProvider.notifier)
        .addNote(
          title: content,
          content: content,
          reminderAt: _reminderAt,
          paperColor: NoteColor.green,
          isTask: true,
        );
    if (!mounted) return;
    ToastUtils.show(_reminderAt == null ? '待办已保存' : '待办和提醒已保存');
    Navigator.pop(context);
  }
}

class _TaskReminderField extends StatelessWidget {
  const _TaskReminderField({
    required this.reminderAt,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? reminderAt;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final active = reminderAt != null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.noteBlue.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
              color: AppColors.accentText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '提醒时间',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active ? formatFullTime(reminderAt!) : '不设置提醒',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: '清除提醒',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
