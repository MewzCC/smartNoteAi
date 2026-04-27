import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/note_model.dart';
import '../../shared/enums/note_priority.dart';

class StickyCard extends StatelessWidget {
  const StickyCard({
    super.key,
    required this.note,
    this.compact = false,
    this.onDelete,
    this.onArchive,
  });

  final NoteModel note;
  final bool compact;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final color = _paperColor(note);
    final accent = _accentColor(note);
    return Slidable(
      key: ValueKey(note.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => onArchive?.call(),
            backgroundColor: AppColors.noteBlue,
            foregroundColor: AppColors.textPrimary,
            icon: Icons.archive_rounded,
            label: '归档',
          ),
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: '删除',
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.normal),
        onTap: () => context.push('/notes/${note.id}'),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.normal),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -11,
                right: -8,
                child: Transform.rotate(
                  angle: note.isPinned ? 0.16 : -0.22,
                  child: Icon(
                    note.isPinned ? Icons.star_rounded : Icons.push_pin_rounded,
                    color: accent,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                right: -12,
                bottom: -14,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                bottom: 38,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 15 : 16,
                        decoration: note.done
                            ? TextDecoration.lineThrough
                            : null,
                        color: note.done
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        note.content,
                        maxLines: compact ? 3 : 7,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          height: 1.35,
                          color: note.done
                              ? AppColors.textSecondary
                              : AppColors.textPrimary.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    formatNoteTime(note.reminderAt ?? note.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _paperColor(NoteModel note) {
    if (note.isArchived) return const Color(0xFFF5F2EA);
    return switch (note.priority) {
      NotePriority.high => AppColors.notePink,
      NotePriority.medium => AppColors.noteYellow,
      NotePriority.low => AppColors.noteGreen,
    };
  }

  Color _accentColor(NoteModel note) {
    return switch (note.priority) {
      NotePriority.high => const Color(0xFFFF7892),
      NotePriority.medium => AppColors.accentText,
      NotePriority.low => const Color(0xFF67C77A),
    };
  }
}
