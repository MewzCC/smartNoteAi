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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: '',
                onPressed: showBack
                    ? () => Navigator.of(context).maybePop()
                    : () => context.push('/profile'),
                icon: Icon(
                  showBack ? Icons.chevron_left_rounded : Icons.menu_rounded,
                ),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: showSearch
                  ? IconButton(
                      tooltip: '',
                      onPressed: () => context.push('/notes'),
                      icon: const Icon(Icons.search_rounded),
                    )
                  : trailing ?? const SizedBox(width: 48, height: 48),
            ),
          ],
        ),
      ),
    );
  }
}
