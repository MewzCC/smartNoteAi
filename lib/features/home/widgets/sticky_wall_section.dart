import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/sticky_card.dart';
import '../../../core/widgets/sticky_dialog.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/components/empty_state.dart';
import '../provider/home_provider.dart';

class StickyWallSection extends ConsumerWidget {
  const StickyWallSection({super.key, required this.notes});

  final List<NoteModel> notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = notes.take(4).toList();
    if (display.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(child: EmptyState(text: '暂无便签', height: 96)),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.crossAxisExtent - 14) / 2;
          final cardHeight = (cardWidth * 0.86).clamp(150.0, 178.0);
          return SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final note = display[index];
              return SizedBox.expand(
                child: StickyCard(
                  note: note,
                  compact: true,
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
            }, childCount: display.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: cardHeight,
            ),
          );
        },
      ),
    );
  }
}
