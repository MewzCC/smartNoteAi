import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class StickyAppBar extends StatelessWidget {
  const StickyAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSearch = true,
    this.trailing,
  });

  final String title;
  final bool showBack;
  final bool showSearch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          IconButton(
            tooltip: showBack ? '返回' : '菜单',
            onPressed: showBack
                ? () => Navigator.of(context).maybePop()
                : () => context.push('/profile'),
            icon: Icon(
              showBack ? Icons.chevron_left_rounded : Icons.menu_rounded,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (showSearch)
            IconButton(
              tooltip: '搜索',
              onPressed: () => context.push('/notes'),
              icon: const Icon(Icons.search_rounded),
            )
          else if (trailing == null)
            const SizedBox(width: 48),
          ?trailing,
        ],
      ),
    );
  }
}
