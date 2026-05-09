import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/enums/reminder_repeat.dart';

class NoteReminderResult {
  const NoteReminderResult({
    required this.enabled,
    this.time,
    this.repeat = ReminderRepeat.none,
  });

  final bool enabled;
  final DateTime? time;
  final ReminderRepeat repeat;
}

class NoteReminderPicker extends StatefulWidget {
  const NoteReminderPicker({
    super.key,
    this.initialTime,
    this.initialRepeat = ReminderRepeat.none,
    required this.onFinish,
  });

  final DateTime? initialTime;
  final ReminderRepeat initialRepeat;
  final ValueChanged<NoteReminderResult> onFinish;

  @override
  State<NoteReminderPicker> createState() => _NoteReminderPickerState();
}

class _NoteReminderPickerState extends State<NoteReminderPicker> {
  late bool _enabled;
  late DateTime _draft;
  late String _repeat;

  @override
  void initState() {
    super.initState();
    final minimum = _minimumReminderTime();
    final initial = widget.initialTime;
    _enabled = initial != null || true; // 默认开启提醒
    _draft = initial != null && initial.isAfter(minimum)
        ? initial
        : minimum.add(const Duration(minutes: 1));
    _repeat = widget.initialRepeat.label;
  }

  @override
  Widget build(BuildContext context) {
    final minimum = _minimumReminderTime();
    final canFinish = !_enabled || _draft.isAfter(minimum);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        StickyAppBar(
          title: '选择提醒时间',
          showBack: true,
          showSearch: false,
          trailing: TextButton(
            onPressed: canFinish ? _finish : null,
            child: const Text('完成'),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('开启提醒'),
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
        ),
        const SizedBox(height: 20),
        Text(
          '${_draft.year}年${_draft.month}月${_draft.day}日 ${_weekdayText(_draft)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 188,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            initialDateTime: _draft,
            minimumDate: minimum,
            maximumDate: DateTime.now().add(const Duration(days: 365)),
            minuteInterval: 1,
            use24hFormat: true,
            onDateTimeChanged: (value) {
              final min = _minimumReminderTime();
              setState(() {
                _draft = value.isAfter(min)
                    ? value
                    : min.add(const Duration(minutes: 1));
              });
            },
          ),
        ),
        const SizedBox(height: 18),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('重复'),
          trailing: Text(_repeat),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: ['不重复', '每天', '每周', '每月', '自定义'].map((item) {
            return ChoiceChip(
              selected: item == _repeat,
              label: Text(item),
              onSelected: (_) => setState(() => _repeat = item),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.noteYellow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.alarm_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _enabled ? '提醒 ${formatFullTime(_draft)}' : '当前不会创建提醒',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '已过去的时间不可选择，请选择当前时间之后的提醒。',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _finish() {
    if (!_enabled) {
      widget.onFinish(const NoteReminderResult(enabled: false));
      return;
    }
    if (!_draft.isAfter(_minimumReminderTime())) {
      ToastUtils.show('请选择未来时间');
      return;
    }
    widget.onFinish(
      NoteReminderResult(
        enabled: true,
        time: _draft,
        repeat: ReminderRepeat.fromLabel(_repeat),
      ),
    );
  }

  DateTime _minimumReminderTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  String _weekdayText(DateTime value) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[value.weekday - 1];
  }
}
