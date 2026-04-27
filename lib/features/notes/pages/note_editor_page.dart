import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../../core/utils/copy_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_input.dart';
import '../../../features/home/provider/home_provider.dart';
import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/note_color.dart';
import '../../../shared/enums/note_priority.dart';
import '../pages/note_preview_page.dart';
import '../pages/note_reminder_page.dart';
import '../widgets/note_ai_write_panel.dart';
import '../widgets/note_checklist_editor.dart';
import '../widgets/note_color_selector.dart';
import '../widgets/note_editor_header.dart';
import '../widgets/note_more_panel.dart';
import '../widgets/note_paper_editor.dart';
import '../widgets/note_reminder_selector.dart';
import '../widgets/note_tag_selector.dart';
import '../widgets/note_toolbar.dart';

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
  late final TextEditingController _aiPrompt;
  Timer? _autoSaveTimer;
  DateTime? _reminderAt;
  NotePriority _priority = NotePriority.medium;
  NoteColor _paperColor = NoteColor.yellow;
  String _tag = '全部';
  bool _isTask = false;
  bool _done = false;
  bool _isPinned = false;
  final bool _autoFocusContent = false;

  bool get _editing => widget.noteId != null;

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
    _aiPrompt = TextEditingController();
    _reminderAt = note?.reminderAt;
    _priority = note?.priority ?? NotePriority.medium;
    _paperColor = note?.paperColor ?? noteColorFromPriority(_priority);
    _tag = note?.tag ?? '全部';
    _isTask = note?.isTask ?? widget.initialIsTask;
    _done = note?.done ?? false;
    _isPinned = note?.isPinned ?? false;
    _title.addListener(_scheduleAutoSave);
    _content.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _title.dispose();
    _content.dispose();
    _newTag.dispose();
    _aiPrompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartNoteProvider);
    final tags = <String>{
      ...state.config.customTags,
      ...state.notes.map((note) => note.tag),
    }.where((tag) => tag.trim().isNotEmpty).toList();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: [
                  NoteEditorHeader(
                    title: _editing ? '编辑便签' : '新建便签',
                    showBack: _editing,
                    onCancel: () => context.pop(),
                    onDone: _saveAndClose,
                  ),
                  NotePaperEditor(
                    titleController: _title,
                    contentController: _content,
                    paperColor: _paperColor,
                    isPinned: _isPinned,
                    autoFocusContent: _autoFocusContent,
                  ),
                  const SizedBox(height: 12),
                  NoteToolbar(
                    onTemplate: _insertTemplate,
                    onAiWrite: _openAiPanel,
                    onChecklist: _openChecklistPanel,
                    onImage: () => ToastUtils.show('图片功能将在后续版本开放'),
                    onVoice: () => ToastUtils.show('语音输入将在后续版本开放'),
                    onMore: _openMorePanel,
                  ),
                  const SizedBox(height: 18),
                  NoteColorSelector(
                    selected: _paperColor,
                    onChanged: (value) {
                      setState(() => _paperColor = value);
                      _scheduleAutoSave();
                    },
                  ),
                  const SizedBox(height: 24),
                  NoteTagSelector(
                    tags: tags,
                    selected: _tag,
                    onChanged: (value) {
                      setState(() => _tag = value);
                      _scheduleAutoSave();
                    },
                    onCreate: _createTag,
                  ),
                  const SizedBox(height: 22),
                  NoteReminderSelector(
                    reminderAt: _reminderAt,
                    onTap: _openReminderPage,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('是否置顶'),
                    value: _isPinned,
                    onChanged: (value) {
                      setState(() => _isPinned = value);
                      _scheduleAutoSave();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('加入任务'),
                    subtitle: const Text('开启后会显示在任务页'),
                    value: _isTask,
                    onChanged: (value) {
                      setState(() => _isTask = value);
                      _scheduleAutoSave();
                    },
                  ),
                  if (_isTask)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('完成状态'),
                      subtitle: const Text('已完成会置灰并显示删除线'),
                      value: _done,
                      onChanged: (value) {
                        setState(() => _done = value);
                        _scheduleAutoSave();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReminderPage() async {
    final result = await Navigator.of(context).push<NoteReminderResult>(
      MaterialPageRoute(
        builder: (context) => NoteReminderPage(initialTime: _reminderAt),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _reminderAt = result.enabled ? result.time : null;
    });
    _scheduleAutoSave();
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
    _scheduleAutoSave();
  }

  void _insertTemplate() {
    final next = ['一、目标', '二、执行步骤', '三、注意事项', '四、完成标准'].join('\n');
    _appendContent(next);
  }

  void _openChecklistPanel() {
    showMaterialModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => NoteChecklistEditor(
        onInsertChecklist: () {
          Navigator.pop(sheetContext);
          _appendContent('- [ ] 任务一\n- [ ] 任务二\n- [ ] 任务三');
        },
        onAppendTodo: () {
          Navigator.pop(sheetContext);
          _appendContent('- [ ] ');
        },
      ),
    );
  }

  void _openAiPanel() {
    _aiPrompt.text = _title.text.trim().isEmpty
        ? _content.text.trim()
        : _title.text.trim();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: NoteAiWritePanel(
                controller: _aiPrompt,
                onGenerate: () async {
                  try {
                    await ref
                        .read(smartNoteProvider.notifier)
                        .generate(_aiPrompt.text);
                    final plans = ref.read(smartNoteProvider).generatedPlans;
                    if (plans.isNotEmpty) {
                      final first = plans.first;
                      if (_title.text.trim().isEmpty) _title.text = first.title;
                      _appendContent(first.content);
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  } catch (_) {
                    ToastUtils.show('AI 生成失败，请检查服务商配置');
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMorePanel() {
    showMaterialModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => NoteMorePanel(
          isPinned: _isPinned,
          isTask: _isTask,
          done: _done,
          onPinChanged: (value) {
            setState(() => _isPinned = value);
            setSheetState(() {});
            _scheduleAutoSave();
          },
          onTaskChanged: (value) {
            setState(() => _isTask = value);
            setSheetState(() {});
            _scheduleAutoSave();
          },
          onDoneChanged: (value) {
            setState(() => _done = value);
            setSheetState(() {});
            _scheduleAutoSave();
          },
          onCopy: () async {
            await CopyUtils.copy('${_title.text}\n\n${_content.text}');
            ToastUtils.show('已复制便签内容');
          },
          onPreview: () {
            Navigator.pop(sheetContext);
            _openPreview();
          },
          onArchive: () async {
            if (!_editing) {
              ToastUtils.show('保存后可归档');
              return;
            }
            await ref
                .read(smartNoteProvider.notifier)
                .toggleArchive(widget.noteId!);
            if (!mounted) return;
            Navigator.of(this.context).pop();
          },
          onDelete: () async {
            if (!_editing) {
              Navigator.pop(sheetContext);
              return;
            }
            await ref
                .read(smartNoteProvider.notifier)
                .deleteNote(widget.noteId!);
            if (!mounted) return;
            Navigator.of(this.context).pop();
          },
        ),
      ),
    );
  }

  void _openPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotePreviewPage(
          title: _title.text.trim(),
          content: _content.text.trim(),
          priority: _priority,
          paperColor: _paperColor,
          tag: _tag,
          isPinned: _isPinned,
          reminderAt: _reminderAt,
        ),
      ),
    );
  }

  void _appendContent(String value) {
    final current = _content.text.trimRight();
    final prefix = current.isEmpty ? '' : '\n';
    _content.text = '$current$prefix$value';
    _content.selection = TextSelection.collapsed(offset: _content.text.length);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (!_editing) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 900), () {
      _save(closeAfterSave: false, showToast: false);
    });
  }

  Future<void> _saveAndClose() => _save(closeAfterSave: true, showToast: true);

  Future<void> _save({
    required bool closeAfterSave,
    required bool showToast,
  }) async {
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
        paperColor: _paperColor,
        tag: _tag,
        isTask: _isTask,
        done: _isTask && _done,
        isPinned: _isPinned,
      );
    } else {
      await controller.updateNote(
        old.copyWith(
          title: title,
          content: content,
          reminderAt: _reminderAt,
          clearReminder: _reminderAt == null,
          priority: _priority,
          paperColor: _paperColor,
          tag: _tag,
          isTask: _isTask,
          done: _isTask && _done,
          isPinned: _isPinned,
        ),
      );
    }
    if (showToast) ToastUtils.show('已保存');
    if (mounted && closeAfterSave) context.pop();
  }
}
