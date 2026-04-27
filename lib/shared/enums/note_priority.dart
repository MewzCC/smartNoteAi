import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum NotePriority { low, medium, high }

extension NotePriorityX on NotePriority {
  String get label => switch (this) {
    NotePriority.low => '低',
    NotePriority.medium => '中',
    NotePriority.high => '高',
  };

  Color get color => switch (this) {
    NotePriority.low => AppColors.noteGreen,
    NotePriority.medium => AppColors.noteYellow,
    NotePriority.high => AppColors.notePink,
  };
}
