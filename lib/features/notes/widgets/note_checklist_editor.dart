import 'package:flutter/material.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_input.dart';
import '../pages/note_reminder_page.dart';

class NoteChecklistEditor extends StatefulWidget {
  const NoteChecklistEditor({
    super.key,
    required this.onCreateTodo,
    this.initialReminderAt,
  });

  final void Function(String content, DateTime? reminderAt) onCreateTodo;
  final DateTime? initialReminderAt;

  @override
  State<NoteChecklistEditor> createState() => _NoteChecklistEditorState();
}

class _NoteChecklistEditorState extends State<NoteChecklistEditor> {
  late final TextEditingController _contentController;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _reminderAt = widget.initialReminderAt;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '新增待办',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            StickyInput(
              controller: _contentController,
              hint: '填写待办内容',
              icon: Icons.add_task_rounded,
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _ReminderTile(
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
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

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ToastUtils.show('请填写待办内容');
      return;
    }

    widget.onCreateTodo(content, _reminderAt);
    Navigator.pop(context);
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminderAt,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? reminderAt;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.noteBlue.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm_rounded),
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
                    reminderAt == null ? '不设置提醒' : formatFullTime(reminderAt!),
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
