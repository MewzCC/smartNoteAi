import 'package:flutter/material.dart';

PageRouteBuilder<T> buildAppPageRoute<T>({
  required Widget child,
  AxisDirection axis = AxisDirection.left,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offset = _beginOffset(axis);

      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Offset _beginOffset(AxisDirection axis) {
  return switch (axis) {
    AxisDirection.up => const Offset(0, 0.08),
    AxisDirection.down => const Offset(0, -0.08),
    AxisDirection.left => const Offset(0.08, 0),
    AxisDirection.right => const Offset(-0.08, 0),
  };
}
