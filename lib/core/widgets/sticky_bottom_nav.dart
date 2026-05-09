import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class StickyBottomNav extends StatelessWidget {
  const StickyBottomNav({super.key, required this.activePath});

  final String activePath;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavSpec(Icons.home_rounded, '首页', '/home'),
      const _NavSpec(Icons.edit_note_rounded, '笔记', '/notes'),
      const _NavSpec(
        Icons.smart_toy_rounded,
        'AI便签',
        '/ai',
        'assets/icon/ai_bot.png',
      ),
      const _NavSpec(Icons.check_box_outlined, '任务', '/tasks'),
      const _NavSpec(Icons.calendar_month_rounded, '日历', '/calendar'),
    ];
    return Container(
      height: 74,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xLarge),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final item in items)
            _NavItem(
              spec: item,
              active: activePath == item.path,
              onTap: () => context.go(item.path),
            ),
        ],
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.label, this.path, [this.asset]);

  final IconData icon;
  final String label;
  final String path;
  final String? asset;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.active,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.small),
      onTap: onTap,
      child: AnimatedScale(
        scale: active ? 1.04 : 0.96,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 58,
          transform: Matrix4.translationValues(0, active ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.82)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.small),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: spec.asset == null
                    ? Icon(spec.icon, size: 24)
                    : ClipOval(
                        child: Image.asset(
                          spec.asset!,
                          width: 26,
                          height: 26,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: active ? AppColors.accentText : AppColors.textPrimary,
                ),
                child: Text(spec.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
