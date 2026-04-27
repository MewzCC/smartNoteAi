import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_tag.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/components/app_scaffold.dart';
import '../../../shared/components/empty_state.dart';
import '../provider/task_provider.dart';

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
        onPressed: () => context.push('/notes/new?task=1'),
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
                  if (value == 'new') context.push('/notes/new?task=1');
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
            else if (_filter == '已完成')
              _TaskGroup(title: '已完成', notes: notes)
            else ...[
              _TaskGroup(title: '今天', notes: notes.take(2).toList()),
              _TaskGroup(title: '本周', notes: notes.skip(2).take(2).toList()),
              _TaskGroup(title: '本月', notes: notes.skip(4).toList()),
            ],
          ],
        ),
      ),
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
              tooltip: note.done ? '标记为待办' : '标记为完成',
              onPressed: () =>
                  ref.read(smartNoteProvider.notifier).toggleDone(note.id),
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
            if (note.reminderAt != null)
              Text(
                '${note.reminderAt!.hour.toString().padLeft(2, '0')}:${note.reminderAt!.minute.toString().padLeft(2, '0')}',
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
