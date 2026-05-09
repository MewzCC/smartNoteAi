import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/home/provider/home_provider.dart';
import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/note_color.dart';
import '../../../shared/helpers/checklist_helper.dart';
import 'note_reminder_page.dart';
import '../widgets/note_checklist_content.dart';

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
    final canComplete = canCompleteTaskContent(note.content);

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
                                      child: NoteChecklistContent(
                                        content: note.content,
                                        textStyle: const TextStyle(height: 1.8),
                                        onToggle: (lineIndex) async {
                                          final nextContent =
                                              toggleChecklistLine(
                                                note.content,
                                                lineIndex,
                                              );
                                          await ref
                                              .read(smartNoteProvider.notifier)
                                              .updateNote(
                                                note.copyWith(
                                                  content: nextContent,
                                                  done:
                                                      note.isTask &&
                                                          hasChecklistLines(
                                                            nextContent,
                                                          )
                                                      ? areChecklistLinesComplete(
                                                          nextContent,
                                                        )
                                                      : note.done,
                                                ),
                                              );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _StatusMeta(
                                        icon: Icons.sell_outlined,
                                        label: note.tag,
                                      ),
                                      if (note.isTask)
                                        _StatusMeta(
                                          icon: note.done
                                              ? Icons.check_box_rounded
                                              : Icons
                                                    .check_box_outline_blank_rounded,
                                          label: note.done ? '已完成' : '任务',
                                        ),
                                      if (note.reminderAt != null)
                                        ActionChip(
                                          avatar: const Icon(
                                            Icons.alarm_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            formatFullTime(note.reminderAt!),
                                          ),
                                          onPressed: () async {
                                            final result =
                                                await Navigator.of(
                                                  context,
                                                ).push<NoteReminderResult>(
                                                  buildAppPageRoute(
                                                    child: NoteReminderPage(
                                                      initialTime:
                                                          note.reminderAt,
                                                    ),
                                                    axis: AxisDirection.up,
                                                  ),
                                                );
                                            if (result == null) return;
                                            await ref
                                                .read(
                                                  smartNoteProvider.notifier,
                                                )
                                                .updateNote(
                                                  note.copyWith(
                                                    reminderAt: result.time,
                                                    clearReminder:
                                                        !result.enabled,
                                                  ),
                                                );
                                          },
                                        ),
                                    ],
                                  ),
                                  if (note.isTask) ...[
                                    const SizedBox(height: 12),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: note.done || canComplete
                                          ? () => ref
                                                .read(
                                                  smartNoteProvider.notifier,
                                                )
                                                .toggleDone(note.id)
                                          : null,
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
                                            Text(
                                              note.done
                                                  ? '已完成'
                                                  : canComplete
                                                  ? '标记为完成'
                                                  : '完成所有待办后可标记',
                                            ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BottomTool(
                        icon: Icons.edit_rounded,
                        tooltip: '编辑',
                        onTap: () => context.push('/notes/$noteId/edit'),
                      ),
                      _BottomTool(
                        icon: Icons.delete_outline_rounded,
                        tooltip: '删除',
                        onTap: () async {
                          await ref
                              .read(smartNoteProvider.notifier)
                              .deleteNote(noteId);
                          if (context.mounted) context.pop();
                        },
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

class _StatusMeta extends StatelessWidget {
  const _StatusMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTool extends StatelessWidget {
  const _BottomTool({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}
