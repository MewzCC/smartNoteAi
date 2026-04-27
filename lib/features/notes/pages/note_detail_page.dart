import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/copy_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../features/home/provider/home_provider.dart';
import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/note_priority.dart';

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
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  StickyAppBar(
                    title: '笔记详情',
                    showBack: true,
                    showSearch: false,
                    trailing: PopupMenuButton<String>(
                      tooltip: '更多',
                      icon: const Icon(Icons.more_horiz_rounded),
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('编辑')),
                        PopupMenuItem(value: 'archive', child: Text('归档')),
                        PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                  ),
                  Container(
                    height: 620,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: note.priority.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(note.content, style: const TextStyle(height: 1.8)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(label: Text(note.tag)),
                            if (note.isTask)
                              Chip(
                                avatar: Icon(
                                  note.done
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
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
                                label: Text(formatFullTime(note.reminderAt!)),
                              ),
                          ],
                        ),
                        if (note.isTask) ...[
                          const SizedBox(height: 18),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => ref
                                .read(smartNoteProvider.notifier)
                                .toggleDone(note.id),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.36),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    note.done
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(note.done ? '已完成' : '标记为完成'),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              note.reminderAt == null
                                  ? '创建于 ${formatFullTime(note.createdAt)}'
                                  : '提醒 ${formatFullTime(note.reminderAt!)}',
                            ),
                          ],
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
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                _BottomTool(
                  icon: Icons.ios_share_rounded,
                  onTap: () async {
                    await CopyUtils.copy('${note.title}\n\n${note.content}');
                    ToastUtils.show('已复制便签内容');
                  },
                ),
                const Spacer(),
                _BottomTool(
                  icon: Icons.edit_rounded,
                  onTap: () => context.push('/notes/$noteId/edit'),
                ),
                const Spacer(),
                _BottomTool(
                  icon: Icons.delete_outline_rounded,
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
