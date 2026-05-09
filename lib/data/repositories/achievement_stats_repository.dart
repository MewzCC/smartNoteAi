import 'dart:async';

import '../../core/constants/hive_keys.dart';
import '../local/hive_boxes.dart';
import '../models/achievement_stats_model.dart';

class AchievementStatsRepository {
  AchievementStatsModel loadStats() {
    final raw = HiveBoxes.config.get(HiveKeys.achievementStats);
    if (raw is Map) {
      return AchievementStatsModel.fromJson(Map<String, dynamic>.from(raw));
    }

    const initialStats = AchievementStatsModel();
    unawaited(saveStats(initialStats));
    return initialStats;
  }

  Future<void> saveStats(AchievementStatsModel stats) {
    return HiveBoxes.config.put(HiveKeys.achievementStats, stats.toJson());
  }
}
