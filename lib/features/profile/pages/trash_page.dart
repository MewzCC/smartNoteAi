import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/enums/note_priority.dart';
import '../provider/profile_provider.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(smartNoteProvider).trashNotes;
    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
          children: [
            const StickyAppBar(title: '回收站', showBack: true, showSearch: false),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.noteYellow.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Text('删除的便签会在这里保留 14 天，之后自动永久清除。'),
            ),
            const SizedBox(height: 14),
            if (notes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: EmptyState(
                  text: '回收站是空的',
                  icon: Icons.delete_outline_rounded,
                  height: 140,
                ),
              )
            else
              for (final note in notes) _TrashItem(noteId: note.id),
          ],
        ),
      ),
    );
  }
}

class _TrashItem extends ConsumerWidget {
  const _TrashItem({required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref
        .watch(smartNoteProvider)
        .notes
        .where((item) => item.id == noteId)
        .firstOrNull;
    if (note == null) return const SizedBox.shrink();
    final deletedAt = note.deletedAt;
    final leftDays = deletedAt == null
        ? 0
        : (14 - DateTime.now().difference(deletedAt).inDays).clamp(0, 14);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: note.priority.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            deletedAt == null
                ? '即将清除'
                : '删除于 ${formatFullTime(deletedAt)}，剩余 $leftDays 天',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(smartNoteProvider.notifier).restoreNote(note.id),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('恢复'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmDelete(context, ref, note.id),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('永久删除'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String noteId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除'),
        content: const Text('永久删除后无法恢复，确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(smartNoteProvider.notifier).permanentlyDeleteNote(noteId);
    }
  }
}
