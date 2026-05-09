import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/sticky_app_bar.dart';
import '../../core/widgets/sticky_card.dart';
import '../../core/widgets/sticky_input.dart';
import '../../shared/components/app_scaffold.dart';
import '../../shared/components/empty_state.dart';
import '../home/provider/home_provider.dart';

class ArchivePage extends ConsumerStatefulWidget {
  const ArchivePage({super.key});

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage> {
  final _keyword = TextEditingController();

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartNoteProvider);
    final keyword = _keyword.text.trim();
    final notes = state.archivedNotes
        .where(
          (note) =>
              keyword.isEmpty ||
              note.title.contains(keyword) ||
              note.content.contains(keyword),
        )
        .toList();
    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const StickySliverAppBar(
              title: '归档',
              showBack: true,
              showSearch: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: StickyInput(
                  controller: _keyword,
                  hintText: '搜索归档内容...',
                  icon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (notes.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    text: '暂无归档内容',
                    icon: Icons.archive_outlined,
                    height: 140,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = notes[index];
                    return StickyCard(
                      note: note,
                      compact: true,
                      onArchive: () => ref
                          .read(smartNoteProvider.notifier)
                          .toggleArchive(note.id),
                      onDelete: () => ref
                          .read(smartNoteProvider.notifier)
                          .deleteNote(note.id),
                    );
                  }, childCount: notes.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 166,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 112)),
          ],
        ),
      ),
    );
  }
}
