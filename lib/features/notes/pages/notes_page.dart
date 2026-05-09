import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_card.dart';
import '../../../core/widgets/sticky_dialog.dart';
import '../../../core/widgets/sticky_tag.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/components/app_scaffold.dart';
import '../../../shared/components/empty_state.dart';
import '../provider/notes_provider.dart';

enum _NoteSortType {
  newest('日期最新', Icons.schedule_rounded),
  oldest('日期最早', Icons.history_rounded),
  title('标题排序', Icons.sort_by_alpha_rounded),
  pinned('置顶优先', Icons.push_pin_rounded),
  task('任务优先', Icons.check_box_outlined);

  const _NoteSortType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  String _selectedTag = '全部';
  _NoteSortType _sortType = _NoteSortType.newest;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartNoteProvider);
    final allNotes = state.visibleNotes;
    final filteredNotes = _selectedTag == '全部'
        ? allNotes
        : allNotes.where((note) => note.tag == _selectedTag);
    final notes = _sortedNotes(filteredNotes);
    final tags = <String>{
      '全部',
      '灵感',
      '工作',
      '生活',
      '学习',
      '健康',
      ...allNotes.map((note) => note.tag),
    }.where((tag) => tag.trim().isNotEmpty).toList();

    return AppScaffold(
      activePath: '/notes',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        child: const Icon(Icons.add_rounded),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: StickyAppBar(
                title: '笔记',
                showSearch: false,
                trailing: _SortMenu(
                  selected: _sortType,
                  onChanged: (value) => setState(() => _sortType = value),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _NoteTags(
                tags: tags,
                selected: _selectedTag,
                onChanged: (value) => setState(() => _selectedTag = value),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (notes.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(text: '暂无便签', height: 140),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.crossAxisExtent - 14) / 2;
                    final height = (cardWidth * 1.02).clamp(168.0, 210.0);
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return SizedBox.expand(
                          child: StickyCard(
                            note: note,
                            onArchive: () => ref
                                .read(smartNoteProvider.notifier)
                                .toggleArchive(note.id),
                            onDelete: () async {
                              final ok = await StickyDialog.confirmDelete(
                                context,
                                note.title,
                              );
                              if (!ok) return;
                              await ref
                                  .read(smartNoteProvider.notifier)
                                  .deleteNote(note.id);
                            },
                          ),
                        );
                      }, childCount: notes.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: height,
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  List<NoteModel> _sortedNotes(Iterable<NoteModel> source) {
    final notes = source.toList();
    notes.sort((left, right) {
      if (_sortType == _NoteSortType.pinned) {
        final pinned = _comparePinned(left, right);
        if (pinned != 0) return pinned;
      }

      return switch (_sortType) {
        _NoteSortType.newest => _compareDate(right, left),
        _NoteSortType.oldest => _compareDate(left, right),
        _NoteSortType.title => left.title.compareTo(right.title),
        _NoteSortType.pinned => _compareDate(right, left),
        _NoteSortType.task => _compareTask(left, right),
      };
    });
    return notes;
  }

  int _compareDate(NoteModel left, NoteModel right) {
    final leftTime = left.reminderAt ?? left.createdAt;
    final rightTime = right.reminderAt ?? right.createdAt;
    final result = leftTime.compareTo(rightTime);
    if (result != 0) return result;
    return left.createdAt.compareTo(right.createdAt);
  }

  int _comparePinned(NoteModel left, NoteModel right) {
    if (left.isPinned == right.isPinned) return 0;
    return left.isPinned ? -1 : 1;
  }

  int _compareTask(NoteModel left, NoteModel right) {
    if (left.isTask != right.isTask) return left.isTask ? -1 : 1;
    if (left.done != right.done) return left.done ? 1 : -1;
    return _compareDate(right, left);
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.selected, required this.onChanged});

  final _NoteSortType selected;
  final ValueChanged<_NoteSortType> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_NoteSortType>(
      tooltip: '排序',
      color: const Color(0xFFFFFBED),
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: AppColors.cardShadow,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final item in _NoteSortType.values)
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: item == selected
                      ? AppColors.accentText
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: item == selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                ),
                if (item == selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.accentText,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
      ),
    );
  }
}

class _NoteTags extends StatelessWidget {
  const _NoteTags({
    required this.tags,
    required this.selected,
    required this.onChanged,
  });

  final List<String> tags;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
