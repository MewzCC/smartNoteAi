import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/achievement_repository.dart';

class AchievementPreview extends StatelessWidget {
  const AchievementPreview({
    super.key,
    required this.doneCount,
    required this.streak,
    required this.activeDays,
  });

  final int doneCount;
  final int streak;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    final badgesData = AchievementRepository().build(
      doneCount: doneCount,
      streak: streak,
      activeDays: activeDays,
    );
    return SizedBox(
      height: 128,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = badgesData[index];
          return InkWell(
            onTap: () => context.push('/achievement'),
            child: Container(
              width: 82,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: badges.Badge(
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: AppColors.primary,
                ),
                badgeContent: const SizedBox(width: 6, height: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 38),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemCount: badgesData.length,
      ),
    );
  }
}
