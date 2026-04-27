import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';

class NoteReminderSelector extends StatelessWidget {
  const NoteReminderSelector({
    super.key,
    required this.reminderAt,
    required this.onTap,
  });

  final DateTime? reminderAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.alarm_rounded),
      title: Text(reminderAt == null ? '提醒时间' : formatFullTime(reminderAt!)),
      subtitle: Text(reminderAt == null ? '选择日期、时间和重复方式' : '保存后会创建系统提醒'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
