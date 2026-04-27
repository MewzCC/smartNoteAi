import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/enums/note_color.dart';

class NotePaperEditor extends StatelessWidget {
  const NotePaperEditor({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.paperColor,
    required this.isPinned,
    required this.autoFocusContent,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final NoteColor paperColor;
  final bool isPinned;
  final bool autoFocusContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: '输入标题...',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.72),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: paperColor.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: TextField(
                  controller: contentController,
                  autofocus: autoFocusContent,
                  expands: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '开始记录你的想法...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  style: const TextStyle(height: 1.65),
                ),
              ),
              if (isPinned)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
                ),
              Positioned(
                right: -9,
                bottom: -11,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
