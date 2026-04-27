import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/ai_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_button.dart';
import '../../../shared/components/app_scaffold.dart';
import '../provider/ai_provider.dart';

class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});

  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final _prompt = TextEditingController();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();
  final Map<int, DateTime> _selectedTimes = {};
  final Map<int, TextEditingController> _titleControllers = {};
  final Map<int, TextEditingController> _contentControllers = {};
  final Set<int> _dismissedResults = {};

  @override
  void dispose() {
    _prompt.dispose();
    _scrollController.dispose();
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    for (final controller in _contentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartNoteProvider);
    final configured =
        state.config.apiKey.trim().isNotEmpty &&
        state.config.baseUrl.trim().isNotEmpty &&
        state.config.model.trim().isNotEmpty;
    return AppScaffold(
      activePath: '/ai',
      child: SafeArea(
        child: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
          children: [
            StickyAppBar(
              title: 'AI 智能',
              showSearch: false,
              trailing: IconButton(
                tooltip: '服务商设置',
                onPressed: () => context.push('/profile/ai-settings'),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            _HeroPanel(provider: state.config.provider),
            const SizedBox(height: 12),
            if (!configured)
              _ConfigBanner(onTap: () => context.push('/profile/ai-settings')),
            const SizedBox(height: 14),
            _ToolGrid(
              items: [
                // _AiTool(
                //   '记录灵感',
                //   '把零散想法整理成便签',
                //   Icons.lightbulb_rounded,
                //   '/ai/note',
                // ),
                // _AiTool(
                //   '生成清单',
                //   '拆成可执行待办事项',
                //   Icons.event_note_rounded,
                //   '/ai/task',
                // ),
                // _AiTool(
                //   '整理重点',
                //   '提炼会议和对话行动项',
                //   Icons.auto_fix_high_rounded,
                //   '/ai/chat',
                // ),
                // _AiTool(
                //   '笔记模板',
                //   '生成学习或工作模板',
                //   Icons.note_add_rounded,
                //   '/ai/note',
                // ),
              ],
            ),
            const SizedBox(height: 16),
            _PromptPanel(
              controller: _prompt,
              generating: state.generating,
              onChipTap: (text) => _prompt.text = text,
              onGenerate: _generate,
            ),
            if (_visibleGeneratedEntries(state).isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                key: _resultKey,
                children: [
                  const Text(
                    '生成结果',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addAllGenerated(state),
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: const Text('全部加入任务'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final entry in _visibleGeneratedEntries(state))
                _SlideAway(
                  slideAway: _dismissedResults.contains(entry.key),
                  child: _GeneratedPlanCard(
                    titleController: _titleControllerFor(
                      entry.key,
                      entry.value.title,
                    ),
                    contentController: _contentControllerFor(
                      entry.key,
                      entry.value.content,
                    ),
                    reminderAt:
                        _selectedTimes[entry.key] ??
                        entry.value.reminderAt ??
                        _fallbackFutureTime(entry.key),
                    onPickTime: () => _pickPlanTime(entry.key),
                    onAdd: () => _addOneGenerated(entry),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final config = ref.read(smartNoteProvider).config;
    final configured =
        config.apiKey.trim().isNotEmpty &&
        config.baseUrl.trim().isNotEmpty &&
        config.model.trim().isNotEmpty;
    if (!configured) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('需要先配置 AI 服务商'),
          content: const Text('请填写 API Key、Base URL 和 Model 后再生成内容。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                this.context.push('/profile/ai-settings');
              },
              child: const Text('去设置'),
            ),
          ],
        ),
      );
      return;
    }
    try {
      _clearGeneratedEditors();
      await ref.read(smartNoteProvider.notifier).generate(_prompt.text);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToResult());
    } catch (_) {
      ToastUtils.show('生成失败，请检查服务商配置');
    }
  }

  Future<void> _scrollToResult() async {
    final context = _resultKey.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _pickPlanTime(int index) async {
    final now = DateTime.now();
    final current = _selectedTimes[index] ?? _fallbackFutureTime(index);
    final date = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now)
          ? current
          : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    setState(() {
      _selectedTimes[index] = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  DateTime _fallbackFutureTime(int index) {
    final now = DateTime.now();
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: index + 1));
    return day.add(Duration(hours: 9 + (index % 4) * 3));
  }

  TextEditingController _titleControllerFor(int index, String value) {
    return _titleControllers.putIfAbsent(
      index,
      () => TextEditingController(text: value),
    );
  }

  TextEditingController _contentControllerFor(int index, String value) {
    return _contentControllers.putIfAbsent(
      index,
      () => TextEditingController(text: value),
    );
  }

  void _clearGeneratedEditors() {
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    for (final controller in _contentControllers.values) {
      controller.dispose();
    }
    setState(() {
      _selectedTimes.clear();
      _dismissedResults.clear();
      _titleControllers.clear();
      _contentControllers.clear();
    });
  }

  List<MapEntry<int, GeneratedPlan>> _visibleGeneratedEntries(
    SmartNoteState state,
  ) {
    return state.generatedPlans
        .asMap()
        .entries
        .where((entry) => !_dismissedResults.contains(entry.key))
        .toList();
  }

  GeneratedPlan _editedPlan(MapEntry<int, GeneratedPlan> entry) {
    return entry.value.copyWith(
      title: _titleControllerFor(entry.key, entry.value.title).text.trim(),
      content: _contentControllerFor(
        entry.key,
        entry.value.content,
      ).text.trim(),
    );
  }

  Future<void> _addOneGenerated(MapEntry<int, GeneratedPlan> entry) async {
    final time =
        _selectedTimes[entry.key] ??
        entry.value.reminderAt ??
        _fallbackFutureTime(entry.key);
    await ref
        .read(smartNoteProvider.notifier)
        .addGeneratedPlan(_editedPlan(entry), reminderAt: time);
    setState(() => _dismissedResults.add(entry.key));
    ToastUtils.show('已加入任务');
  }

  Future<void> _addAllGenerated(SmartNoteState state) async {
    final entries = _visibleGeneratedEntries(state);
    if (entries.isEmpty) return;
    for (final entry in entries) {
      final time =
          _selectedTimes[entry.key] ??
          entry.value.reminderAt ??
          _fallbackFutureTime(entry.key);
      await ref
          .read(smartNoteProvider.notifier)
          .addGeneratedPlan(_editedPlan(entry), reminderAt: time);
    }
    setState(() {
      _dismissedResults.addAll(entries.map((entry) => entry.key));
    });
    ToastUtils.show('已全部加入任务');
  }
}

class _SlideAway extends StatelessWidget {
  const _SlideAway({required this.slideAway, required this.child});

  final bool slideAway;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: slideAway ? const Offset(-1.15, 0) : Offset.zero,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: slideAway ? 0 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          child: slideAway ? const SizedBox.shrink() : child,
        ),
      ),
    );
  }
}

class _GeneratedPlanCard extends StatelessWidget {
  const _GeneratedPlanCard({
    required this.titleController,
    required this.contentController,
    required this.reminderAt,
    required this.onPickTime,
    required this.onAdd,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final DateTime reminderAt;
  final VoidCallback onPickTime;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.noteYellow,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            maxLines: 1,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              filled: false,
              hintText: '标题',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Expanded(
            child: TextField(
              controller: contentController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                filled: false,
                hintText: '内容',
              ),
              style: const TextStyle(height: 1.4),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickTime,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentText,
                    side: const BorderSide(color: AppColors.accentText),
                  ),
                  icon: const Icon(Icons.alarm_rounded, size: 18),
                  label: FittedBox(child: Text(formatFullTime(reminderAt))),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.accentText,
                  backgroundColor: Colors.white.withValues(alpha: 0.46),
                ),
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('加入这条'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.provider});

  final String provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.notePurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '你好呀，我是你的 AI 智能助手',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '当前服务商：$provider',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigBanner extends StatelessWidget {
  const _ConfigBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.noteYellow.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accentText),
            SizedBox(width: 10),
            Expanded(child: Text('还没有配置 AI 服务商，点击这里去设置。')),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _PromptPanel extends StatelessWidget {
  const _PromptPanel({
    required this.controller,
    required this.generating,
    required this.onChipTap,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final bool generating;
  final ValueChanged<String> onChipTap;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '你想让 AI 帮你做什么？',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['生成周计划', '帮我拆解任务', '整理会议重点', '制定学习计划'].map((text) {
              return ActionChip(
                label: Text(text),
                onPressed: () => onChipTap(text),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '输入你的想法或者需求...',
              filled: true,
              fillColor: Color(0xFFFFFBEB),
            ),
          ),
          const SizedBox(height: 12),
          StickyButton(
            label: generating ? '生成中...' : '生成内容',
            icon: Icons.auto_awesome_rounded,
            onPressed: generating ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class _AiTool {
  const _AiTool(this.title, this.desc, this.icon, this.path);

  final String title;
  final String desc;
  final IconData icon;
  final String path;
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.items});

  final List<_AiTool> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 122,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(item.path),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: AppColors.secondary),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
