import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'note_priority.dart';

enum NoteColor { yellow, green, pink, blue, purple, cream }

extension NoteColorX on NoteColor {
  String get label => switch (this) {
    NoteColor.yellow => '暖黄',
    NoteColor.green => '薄荷',
    NoteColor.pink => '樱粉',
    NoteColor.blue => '晴蓝',
    NoteColor.purple => '浅紫',
    NoteColor.cream => '米白',
  };

  Color get color => switch (this) {
    NoteColor.yellow => AppColors.noteYellow,
    NoteColor.green => AppColors.noteGreen,
    NoteColor.pink => AppColors.notePink,
    NoteColor.blue => AppColors.noteBlue,
    NoteColor.purple => AppColors.notePurple,
    NoteColor.cream => const Color(0xFFFFF6DA),
  };

  Color get accent => switch (this) {
    NoteColor.yellow => AppColors.accentText,
    NoteColor.green => const Color(0xFF58B36A),
    NoteColor.pink => const Color(0xFFFF7892),
    NoteColor.blue => const Color(0xFF5FA8F5),
    NoteColor.purple => const Color(0xFF9A75E8),
    NoteColor.cream => const Color(0xFFB99A45),
  };
}

NoteColor noteColorFromPriority(NotePriority priority) {
  return switch (priority) {
    NotePriority.high => NoteColor.pink,
    NotePriority.medium => NoteColor.yellow,
    NotePriority.low => NoteColor.green,
  };
}
