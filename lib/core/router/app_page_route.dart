import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

PageRouteBuilder<T> buildAppPageRoute<T>({
  required Widget child,
  AxisDirection axis = AxisDirection.left,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isMobile = MediaQuery.sizeOf(context).width < 600;
      if (isMobile) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: axis == AxisDirection.up
              ? SharedAxisTransitionType.vertical
              : SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        );
      }

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeScaleTransition(animation: curved, child: child);
    },
  );
}
