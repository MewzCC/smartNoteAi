import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/sticky_app_bar.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../shared/components/app_scaffold.dart';
import '../home/provider/home_provider.dart';

class AchievementPage extends ConsumerWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartNoteProvider);
    final stats = state.achievementStats;
    final achievements = AchievementRepository().build(
      doneCount: stats.doneTasks,
      streak: stats.currentStreak,
      activeDays: stats.activeDays,
    );
    final progress = stats.completionRate.clamp(0.0, 1.0);

    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
          children: [
            const StickyAppBar(
              title: '成就徽章',
              showBack: true,
              showSearch: false,
            ),
            _SummaryCard(
              totalNotes: stats.totalNotes,
              doneCount: stats.doneTasks,
              streak: stats.currentStreak,
              progress: progress,
            ),
            const SizedBox(height: 18),
            const Text(
              '我的徽章',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 14) / 2;
                final cardHeight = cardWidth.clamp(154.0, 184.0);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: achievements.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    return _AchievementCard(item: achievements[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            _GuideCard(
              doneCount: stats.doneTasks,
              activeDays: stats.activeDays,
              pendingCount: state.pendingCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalNotes,
    required this.doneCount,
    required this.streak,
    required this.progress,
  });

  final int totalNotes;
  final int doneCount;
  final int streak;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.noteYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.accentText,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '继续记录，美好会慢慢累积',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '已记录 $totalNotes 条内容，完成 $doneCount 个任务',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: '连续天数', value: '$streak 天'),
              const SizedBox(width: 10),
              _Metric(label: '完成率', value: '${(progress * 100).round()}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.noteYellow.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final AchievementModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -8,
            right: -2,
            child: CircleAvatar(radius: 7, backgroundColor: AppColors.primary),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 42, color: AppColors.textPrimary),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.doneCount,
    required this.activeDays,
    required this.pendingCount,
  });

  final int doneCount;
  final int activeDays;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.noteBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '下一枚徽章',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            pendingCount == 0
                ? '今天状态很好，可以继续记录一个新想法。'
                : '还有 $pendingCount 个任务待完成，完成后会刷新你的成就进度。',
            style: const TextStyle(height: 1.55, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            '累计完成 $doneCount 个任务，已活跃记录 $activeDays 天。',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
