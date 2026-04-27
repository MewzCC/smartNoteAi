import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/home/provider/home_provider.dart';
import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/note_color.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref
        .watch(smartNoteProvider)
        .notes
        .where((item) => item.id == noteId)
        .firstOrNull;
    if (note == null) {
      return const Scaffold(body: Center(child: Text('便签不存在')));
    }

    final viewportHeight = MediaQuery.sizeOf(context).height;
    final cardHeight = (viewportHeight - 190).clamp(430.0, 640.0);

    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    sliver: SliverList.list(
                      children: [
                        _DetailHeader(
                          onBack: () => Navigator.of(context).maybePop(),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              context.push('/notes/$noteId/edit');
                            }
                            if (value == 'archive') {
                              await ref
                                  .read(smartNoteProvider.notifier)
                                  .toggleArchive(noteId);
                              if (context.mounted) context.pop();
                            }
                            if (value == 'delete') {
                              await ref
                                  .read(smartNoteProvider.notifier)
                                  .deleteNote(noteId);
                              if (context.mounted) context.pop();
                            }
                          },
                        ),
                        SizedBox(
                          height: cardHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: note.paperColor.color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Text(
                                        note.content,
                                        style: const TextStyle(height: 1.8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(label: Text(note.tag)),
                                      if (note.isTask)
                                        Chip(
                                          avatar: Icon(
                                            note.done
                                                ? Icons.check_box_rounded
                                                : Icons
                                                      .check_box_outline_blank_rounded,
                                            size: 16,
                                          ),
                                          label: Text(note.done ? '已完成' : '任务'),
                                        ),
                                      if (note.reminderAt != null)
                                        Chip(
                                          avatar: const Icon(
                                            Icons.alarm_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            formatFullTime(note.reminderAt!),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (note.isTask) ...[
                                    const SizedBox(height: 12),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => ref
                                          .read(smartNoteProvider.notifier)
                                          .toggleDone(note.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.36,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              note.done
                                                  ? Icons.check_box_rounded
                                                  : Icons
                                                        .check_box_outline_blank_rounded,
                                              color: AppColors.success,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(note.done ? '已完成' : '标记为完成'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      note.reminderAt == null
                                          ? '创建于 ${formatFullTime(note.createdAt)}'
                                          : '提醒 ${formatFullTime(note.reminderAt!)}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: _BottomTool(
                          icon: Icons.edit_rounded,
                          onTap: () => context.push('/notes/$noteId/edit'),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _BottomTool(
                          icon: Icons.delete_outline_rounded,
                          onTap: () async {
                            await ref
                                .read(smartNoteProvider.notifier)
                                .deleteNote(noteId);
                            if (context.mounted) context.pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack, required this.onSelected});

  final VoidCallback onBack;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: '返回',
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            const Text(
              '笔记详情',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                tooltip: '更多',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: onSelected,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(value: 'archive', child: Text('归档')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTool extends StatelessWidget {
  const _BottomTool({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(onPressed: onTap, icon: Icon(icon));
  }
}
