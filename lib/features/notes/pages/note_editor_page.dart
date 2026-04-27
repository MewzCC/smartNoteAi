import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_input.dart';
import '../../../core/widgets/sticky_tag.dart';
import '../../../features/home/provider/home_provider.dart';
import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/note_priority.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.noteId, this.initialIsTask = false});

  final String? noteId;
  final bool initialIsTask;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _newTag;
  DateTime? _reminderAt;
  NotePriority _priority = NotePriority.medium;
  String _tag = '全部';
  bool _isTask = false;

  @override
  void initState() {
    super.initState();
    final note = widget.noteId == null
        ? null
        : ref
              .read(smartNoteProvider)
              .notes
              .where((item) => item.id == widget.noteId)
              .firstOrNull;
    _title = TextEditingController(text: note?.title ?? '');
    _content = TextEditingController(text: note?.content ?? '');
    _newTag = TextEditingController();
    _reminderAt = note?.reminderAt;
    _priority = note?.priority ?? NotePriority.medium;
    _tag = note?.tag ?? '全部';
    _isTask = note?.isTask ?? widget.initialIsTask;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _newTag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.noteId != null;
    final tags = <String>{
      ...ref.watch(smartNoteProvider).config.customTags,
      ...ref.watch(smartNoteProvider).notes.map((note) => note.tag),
    }.where((tag) => tag.trim().isNotEmpty).toList();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  StickyAppBar(
                    title: editing ? '编辑笔记' : '新增笔记',
                    showBack: true,
                    showSearch: false,
                    trailing: TextButton(
                      onPressed: _save,
                      child: const Text('完成'),
                    ),
                  ),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      hintText: '标题（可选）',
                      filled: false,
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.noteYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _content,
                      expands: true,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: '开始记录你的想法...',
                        filled: false,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final item in NotePriority.values)
                        ChoiceChip(
                          selected: item == _priority,
                          label: Text('${item.label}优先级'),
                          onSelected: (_) => setState(() => _priority = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final tag in tags)
                        StickyTag(
                          label: tag,
                          selected: tag == _tag,
                          onTap: () => setState(() => _tag = tag),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('新建标签'),
                        onPressed: _createTag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('加入任务'),
                    subtitle: const Text('开启后才会出现在任务页'),
                    value: _isTask,
                    onChanged: (value) => setState(() => _isTask = value),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: const Icon(Icons.alarm_rounded),
                    title: Text(
                      _reminderAt == null
                          ? '设置提醒时间'
                          : formatFullTime(_reminderAt!),
                    ),
                    subtitle: Text(
                      _reminderAt == null
                          ? '请选择具体日期和当天时间'
                          : '已选择具体提醒时间，保存后会创建系统提醒',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickReminder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickReminder() async {
    var draft = _reminderAt ?? DateTime.now().add(const Duration(hours: 1));
    await showMaterialModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择提醒时间',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.noteYellow.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('当前选择'),
                      const SizedBox(height: 6),
                      Text(
                        formatFullTime(draft),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: draft.isAfter(now)
                                ? draft
                                : now.add(const Duration(days: 1)),
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                            locale: const Locale('zh', 'CN'),
                          );
                          if (date == null) return;
                          setSheetState(() {
                            draft = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              draft.hour,
                              draft.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('选择日期'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(draft),
                          );
                          if (time == null) return;
                          final next = DateTime(
                            draft.year,
                            draft.month,
                            draft.day,
                            time.hour,
                            time.minute,
                          );
                          setSheetState(() {
                            draft = next.isAfter(now)
                                ? next
                                : now.add(const Duration(hours: 1));
                          });
                        },
                        icon: const Icon(Icons.schedule_rounded),
                        label: const Text('选择时间'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    if (!draft.isAfter(DateTime.now())) {
                      ToastUtils.show('请选择未来时间');
                      return;
                    }
                    setState(() {
                      _reminderAt = draft;
                    });
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('确定提醒时间'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _reminderAt = null);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('清除提醒'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    _newTag.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: StickyInput(controller: _newTag, hint: '输入标签名称'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _newTag.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    await ref.read(smartNoteProvider.notifier).addCustomTag(value);
    setState(() => _tag = value);
  }

  Future<void> _save() async {
    final title = _title.text.trim().isEmpty ? '未命名笔记' : _title.text.trim();
    final content = _content.text.trim();
    if (content.isEmpty) {
      ToastUtils.show('请填写内容');
      return;
    }
    final controller = ref.read(smartNoteProvider.notifier);
    final old = widget.noteId == null
        ? null
        : ref
              .read(smartNoteProvider)
              .notes
              .where((item) => item.id == widget.noteId)
              .firstOrNull;
    if (old == null) {
      await controller.addNote(
        title: title,
        content: content,
        reminderAt: _reminderAt,
        priority: _priority,
        tag: _tag,
        isTask: _isTask,
      );
    } else {
      await controller.updateNote(
        old.copyWith(
          title: title,
          content: content,
          reminderAt: _reminderAt,
          clearReminder: _reminderAt == null,
          priority: _priority,
          tag: _tag,
          isTask: _isTask,
        ),
      );
    }
    if (mounted) context.pop();
  }
}
