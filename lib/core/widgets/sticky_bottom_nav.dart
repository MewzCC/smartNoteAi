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
      _NavSpec(Icons.home_rounded, '首页', '/home'),
      _NavSpec(Icons.edit_note_rounded, '笔记', '/notes'),
      _NavSpec(Icons.smart_toy_rounded, 'AI便签', '/ai'),
      _NavSpec(Icons.check_box_outlined, '任务', '/tasks'),
      _NavSpec(Icons.calendar_month_rounded, '日历', '/calendar'),
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
  const _NavSpec(this.icon, this.label, this.path);

  final IconData icon;
  final String label;
  final String path;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.78)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, size: 24),
            const SizedBox(height: 3),
            Text(
              spec.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
