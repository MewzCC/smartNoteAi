import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/sticky_app_bar.dart';
import '../../../core/widgets/sticky_card.dart';
import '../../../core/widgets/sticky_dialog.dart';
import '../../../core/widgets/sticky_tag.dart';
import '../../../shared/components/app_scaffold.dart';
import '../../../shared/components/empty_state.dart';
import '../provider/notes_provider.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  String _selectedTag = '全部';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartNoteProvider);
    final allNotes = state.visibleNotes;
    final notes = _selectedTag == '全部'
        ? allNotes
        : allNotes.where((note) => note.tag == _selectedTag).toList();
    final tags = <String>{
      '全部',
      '灵感',
      '工作',
      '生活',
      '学习',
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
            const SliverToBoxAdapter(child: StickyAppBar(title: '笔记')),
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
                              if (ok) {
                                await ref
                                    .read(smartNoteProvider.notifier)
                                    .deleteNote(note.id);
                              }
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
