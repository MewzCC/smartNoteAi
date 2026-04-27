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
            child: child,
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
