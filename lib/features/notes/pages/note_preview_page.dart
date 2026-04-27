import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/paper_background.dart';
import '../../../shared/enums/note_color.dart';
import '../../../shared/enums/note_priority.dart';

class NotePreviewPage extends StatelessWidget {
  const NotePreviewPage({
    super.key,
    required this.title,
    required this.content,
    required this.priority,
    required this.paperColor,
    required this.tag,
    required this.isPinned,
    this.reminderAt,
  });

  final String title;
  final String content;
  final NotePriority priority;
  final NoteColor paperColor;
  final String tag;
  final bool isPinned;
  final DateTime? reminderAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                children: [
                  const StickyAppBar(
                    title: '便签预览',
                    showBack: true,
                    showSearch: false,
                  ),
                  Center(
                    child: Container(
                      width: 300,
                      height: 390,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: paperColor.color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.floating,
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? '未命名笔记' : title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Text(
                                  content,
                                  style: const TextStyle(height: 1.7),
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(label: Text(tag)),
                                  if (reminderAt != null)
                                    Chip(
                                      avatar: const Icon(
                                        Icons.alarm_rounded,
                                        size: 15,
                                      ),
                                      label: Text(formatFullTime(reminderAt!)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (isPinned)
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '当前便签效果会同步首页、笔记列表和详情页展示。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
