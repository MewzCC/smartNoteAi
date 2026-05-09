import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

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
