import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/paper_background.dart';

class NoteReminderPage extends StatefulWidget {
  const NoteReminderPage({super.key, this.initialTime});

  final DateTime? initialTime;

  @override
  State<NoteReminderPage> createState() => _NoteReminderPageState();
}

class NoteReminderResult {
  const NoteReminderResult({required this.enabled, this.time});

  final bool enabled;
  final DateTime? time;
}

class _NoteReminderPageState extends State<NoteReminderPage> {
  late bool _enabled;
  late DateTime _draft;
  String _repeat = '不重复';

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialTime != null;
    _draft = widget.initialTime ?? DateTime.now().add(const Duration(hours: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  StickyAppBar(
                    title: '选择提醒时间',
                    showBack: true,
                    showSearch: false,
                    trailing: TextButton(
                      onPressed: _finish,
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
                    '${_draft.year}年${_draft.month}月${_draft.day}日  ${_weekdayText(_draft)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 188,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: _draft,
                      minimumDate: DateTime.now(),
                      maximumDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      use24hFormat: true,
                      onDateTimeChanged: (value) {
                        setState(() => _draft = value);
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
                            _enabled
                                ? '提醒 ${formatFullTime(_draft)}'
                                : '当前不会创建提醒',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _finish() {
    if (!_enabled) {
      Navigator.pop<NoteReminderResult>(
        context,
        const NoteReminderResult(enabled: false),
      );
      return;
    }
    if (!_draft.isAfter(DateTime.now())) {
      ToastUtils.show('请选择未来时间');
      return;
    }
    Navigator.pop<NoteReminderResult>(
      context,
      NoteReminderResult(enabled: true, time: _draft),
    );
  }

  String _weekdayText(DateTime value) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[value.weekday - 1];
  }
}
