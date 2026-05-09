import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/sticky_bottom_nav.dart';
import 'paper_background.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.activePath,
    required this.child,
    this.floatingActionButton,
  });

  final String activePath;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawerScrimColor: Colors.black.withValues(alpha: 0.38),
      drawerEdgeDragWidth: 44,
      drawer: _StickySideDrawer(activePath: activePath),
      body: PaperBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _MobilePageEntrance(motionKey: activePath, child: child),
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StickyBottomNav(activePath: activePath),
        ),
      ),
    );
  }
}

class _StickySideDrawer extends StatelessWidget {
  const _StickySideDrawer({required this.activePath});

  final String activePath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(0.0, 318.0),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: AppShadows.floating,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.noteYellow.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.accentText,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Note AI',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '记录、提醒和整理灵感',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DrawerTile(
                    icon: Icons.home_rounded,
                    title: '首页',
                    selected: activePath == '/home',
                    onTap: () => _go(context, '/home'),
                  ),
                  _DrawerTile(
                    icon: Icons.edit_note_rounded,
                    title: '笔记',
                    selected: activePath == '/notes',
                    onTap: () => _go(context, '/notes'),
                  ),
                  _DrawerTile(
                    icon: Icons.check_box_rounded,
                    title: '任务',
                    selected: activePath == '/tasks',
                    onTap: () => _go(context, '/tasks'),
                  ),
                  _DrawerTile(
                    icon: Icons.calendar_month_rounded,
                    title: '日历',
                    selected: activePath == '/calendar',
                    onTap: () => _go(context, '/calendar'),
                  ),
                  const Divider(height: 28, color: AppColors.border),
                  _DrawerTile(
                    icon: Icons.emoji_events_rounded,
                    title: '成就徽章',
                    selected: false,
                    onTap: () => _push(context, '/achievement'),
                  ),
                  _DrawerTile(
                    icon: Icons.archive_rounded,
                    title: '归档',
                    selected: false,
                    onTap: () => _push(context, '/archive'),
                  ),
                  _DrawerTile(
                    icon: Icons.tune_rounded,
                    title: 'AI 服务商',
                    selected: false,
                    onTap: () => _push(context, '/profile/ai-settings'),
                  ),
                  _DrawerTile(
                    icon: Icons.delete_outline_rounded,
                    title: '回收站',
                    selected: false,
                    onTap: () => _push(context, '/profile/trash'),
                  ),
                  const Spacer(),
                  Text(
                    '从这里快速切换常用页面',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    if (activePath != path) context.go(path);
  }

  void _push(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.push(path);
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.86)
                : Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.accentText : null),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  color: selected
                      ? AppColors.accentText
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobilePageEntrance extends StatefulWidget {
  const _MobilePageEntrance({required this.motionKey, required this.child});

  final String motionKey;
  final Widget child;

  @override
  State<_MobilePageEntrance> createState() => _MobilePageEntranceState();
}

class _MobilePageEntranceState extends State<_MobilePageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _MobilePageEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionKey != widget.motionKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 600) return widget.child;
    return FadeScaleTransition(
      animation: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.018),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
