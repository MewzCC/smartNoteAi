import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_tag.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/components/app_scaffold.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/helpers/checklist_helper.dart';
import '../provider/task_provider.dart';
import '../widgets/task_create_sheet.dart';

class TaskPage extends ConsumerStatefulWidget {
  const TaskPage({super.key});

  @override
  ConsumerState<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends ConsumerState<TaskPage> {
  String _filter = '待办';

  @override
  Widget build(BuildContext context) {
    final allNotes = ref
        .watch(smartNoteProvider)
        .visibleNotes
        .where((note) => note.isTask)
        .toList();
    final notes = switch (_filter) {
      '全部' => allNotes,
      '待办' => allNotes.where((note) => !note.done).toList(),
      '进行中' =>
        allNotes
            .where((note) => !note.done && note.reminderAt != null)
            .toList(),
      '已完成' => allNotes.where((note) => note.done).toList(),
      _ => allNotes,
    };
    return AppScaffold(
      activePath: '/tasks',
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskSheet,
        child: const Icon(Icons.add_rounded),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
          children: [
            StickyAppBar(
              title: '任务',
              showSearch: false,
              trailing: PopupMenuButton<String>(
                tooltip: '更多',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) {
                  if (value == 'new') _openCreateTaskSheet();
                  if (value == 'ai') context.push('/ai/task');
                  if (value == 'archive') context.push('/archive');
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'new', child: Text('新建任务')),
                  PopupMenuItem(value: 'ai', child: Text('AI 生成任务')),
                  PopupMenuItem(value: 'archive', child: Text('查看归档')),
                ],
              ),
            ),
            _TaskTags(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            if (notes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: EmptyState(
                  text: '暂无$_filter任务',
                  icon: Icons.check_box_outlined,
                  height: 140,
                ),
              )
            else
              _TaskSections(notes: notes),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateTaskSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskCreateSheet(),
    );
  }
}

class _TaskSections extends StatelessWidget {
  const _TaskSections({required this.notes});

  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context) {
    final buckets = _TaskBuckets.from(notes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TaskGroup(title: '今天', notes: buckets.today),
        if (buckets.thisWeek.isNotEmpty)
          _WeekTaskGroup(dayNotes: buckets.thisWeek),
        for (final entry in buckets.otherDays.entries)
          _TaskGroup(title: _dayTitle(entry.key), notes: entry.value),
        _TaskGroup(title: '未设置日期', notes: buckets.noDate),
      ],
    );
  }
}

class _TaskTags extends StatelessWidget {
  const _TaskTags({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const tags = ['全部', '待办', '进行中', '已完成'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => StickyTag(
          label: tags[index],
          selected: tags[index] == selected,
          onTap: () => onChanged(tags[index]),
        ),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: tags.length,
      ),
    );
  }
}

class _WeekTaskGroup extends StatelessWidget {
  const _WeekTaskGroup({required this.dayNotes});

  final Map<DateTime, List<NoteModel>> dayNotes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: true,
          title: const Text(
            '本周',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          children: [
            for (final entry in dayNotes.entries)
              _TaskDayBlock(title: _dayTitle(entry.key), notes: entry.value),
          ],
        ),
      ),
    );
  }
}

class _TaskDayBlock extends StatelessWidget {
  const _TaskDayBlock({required this.title, required this.notes});

  final String title;
  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          for (final note in notes) _TaskTile(note: note),
        ],
      ),
    );
  }
}

class _TaskGroup extends StatelessWidget {
  const _TaskGroup({required this.title, required this.notes});

  final String title;
  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final note in notes) _TaskTile(note: note),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.note});

  final NoteModel note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canComplete = canCompleteTaskContent(note.content);
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/notes/${note.id}'),
        child: Row(
          children: [
            IconButton(
              tooltip: note.done
                  ? '标记为待办'
                  : canComplete
                  ? '标记为完成'
                  : '完成所有待办后可标记',
              onPressed: note.done || canComplete
                  ? () =>
                        ref.read(smartNoteProvider.notifier).toggleDone(note.id)
                  : null,
              icon: Icon(
                note.done
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: note.done ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  decoration: note.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              _formatTaskTime(note.reminderAt),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (!note.done) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: note.isPinned ? '取消置顶' : '置顶任务',
                onPressed: () =>
                    ref.read(smartNoteProvider.notifier).togglePin(note.id),
                icon: Icon(
                  note.isPinned
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.accentText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskBuckets {
  const _TaskBuckets({
    required this.today,
    required this.thisWeek,
    required this.otherDays,
    required this.noDate,
  });

  final List<NoteModel> today;
  final Map<DateTime, List<NoteModel>> thisWeek;
  final Map<DateTime, List<NoteModel>> otherDays;
  final List<NoteModel> noDate;

  factory _TaskBuckets.from(List<NoteModel> notes) {
    final today = dateOnly(DateTime.now());
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sorted = [...notes]..sort(_compareTask);
    final todayNotes = <NoteModel>[];
    final thisWeek = <DateTime, List<NoteModel>>{};
    final otherDays = <DateTime, List<NoteModel>>{};
    final noDate = <NoteModel>[];

    for (final note in sorted) {
      final reminder = note.reminderAt;
      if (reminder == null) {
        noDate.add(note);
        continue;
      }
      final day = dateOnly(reminder);
      if (day.isAtSameMomentAs(today)) {
        todayNotes.add(note);
      } else if (!day.isBefore(weekStart) && day.isBefore(weekEnd)) {
        thisWeek.putIfAbsent(day, () => <NoteModel>[]).add(note);
      } else {
        otherDays.putIfAbsent(day, () => <NoteModel>[]).add(note);
      }
    }

    return _TaskBuckets(
      today: todayNotes,
      thisWeek: thisWeek,
      otherDays: otherDays,
      noDate: noDate,
    );
  }
}

int _compareTask(NoteModel a, NoteModel b) {
  final aTime = a.reminderAt ?? a.createdAt;
  final bTime = b.reminderAt ?? b.createdAt;
  return aTime.compareTo(bTime);
}

String _formatTaskTime(DateTime? value) {
  if (value == null) return '未设置';
  final today = dateOnly(DateTime.now());
  final day = dateOnly(value);
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  if (day.isAtSameMomentAs(today)) return time;
  return '${value.month}月${value.day}日 $time';
}

String _dayTitle(DateTime value) {
  final today = dateOnly(DateTime.now());
  final day = dateOnly(value);
  if (day.isAtSameMomentAs(today)) return '今天';
  if (day.isAtSameMomentAs(today.add(const Duration(days: 1)))) return '明天';
  return '${value.month}月${value.day}日 ${_weekdayText(value)}';
}

String _weekdayText(DateTime value) {
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[value.weekday - 1];
}
