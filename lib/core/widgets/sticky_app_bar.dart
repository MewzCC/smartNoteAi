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
    this.onMenuPressed,
    this.onSearchPressed,
  });

  final String title;
  final bool showBack;
  final bool showSearch;
  final Widget? trailing;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;

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
                    : onMenuPressed ??
                          () {
                            final scaffold = Scaffold.maybeOf(context);
                            if (scaffold?.hasDrawer ?? false) {
                              scaffold!.openDrawer();
                              return;
                            }
                            context.push('/profile');
                          },
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
                      onPressed:
                          onSearchPressed ??
                          () => context.go('/notes?search=1'),
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

class StickySliverAppBar extends StatelessWidget {
  const StickySliverAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showSearch = true,
    this.trailing,
    this.onMenuPressed,
    this.onSearchPressed,
  });

  final String title;
  final bool showBack;
  final bool showSearch;
  final Widget? trailing;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyAppBarDelegate(
        child: StickyAppBar(
          title: title,
          showBack: showBack,
          showSearch: showSearch,
          trailing: trailing,
          onMenuPressed: onMenuPressed,
          onSearchPressed: onSearchPressed,
        ),
      ),
    );
  }
}

class _StickyAppBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyAppBarDelegate({required this.child});

  static const double _height = 72;

  final Widget child;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.94),
        boxShadow: overlapsContent
            ? const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyAppBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
