import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/achievement_model.dart';

class AchievementRepository {
  List<AchievementModel> build({
    required int doneCount,
    required int streak,
    required int activeDays,
  }) {
    return [
      const AchievementModel(
        title: '星标不懒',
        desc: '连续记录 7 天',
        icon: Icons.star_rounded,
        color: AppColors.noteYellow,
      ),
      AchievementModel(
        title: '整理能手',
        desc: '整理笔记 $activeDays 天',
        icon: Icons.verified_rounded,
        color: AppColors.noteGreen,
      ),
      AchievementModel(
        title: '高效达人',
        desc: '完成 $doneCount 个任务',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.notePink,
      ),
      AchievementModel(
        title: '灵感捕手',
        desc: '连续 $streak 天',
        icon: Icons.military_tech_rounded,
        color: AppColors.noteBlue,
      ),
      const AchievementModel(
        title: '分享之星',
        desc: '分享 10 条笔记',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.notePurple,
      ),
    ];
  }
}
