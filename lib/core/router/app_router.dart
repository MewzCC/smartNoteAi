import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/achievement_page.dart';
import '../../features/ai/pages/ai_chat_page.dart';
import '../../features/ai/pages/ai_generate_note_page.dart';
import '../../features/ai/pages/ai_generate_task_page.dart';
import '../../features/ai/pages/ai_page.dart';
import '../../features/archive/archive_page.dart';
import '../../features/calendar/pages/calendar_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/notes/pages/note_detail_page.dart';
import '../../features/notes/pages/note_editor_page.dart';
import '../../features/notes/pages/notes_page.dart';
import '../../features/profile/pages/ai_settings_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/profile/pages/provider_guide_page.dart';
import '../../features/profile/pages/trash_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/tasks/pages/task_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    _route('/splash', const SplashPage()),
    _route('/home', const HomePage()),
    _route('/notes', const NotesPage()),
    GoRoute(
      path: '/notes/new',
      pageBuilder: (context, state) => _page(
        state,
        NoteEditorPage(initialIsTask: state.uri.queryParameters['task'] == '1'),
      ),
    ),
    GoRoute(
      path: '/notes/:id',
      pageBuilder: (context, state) =>
          _page(state, NoteDetailPage(noteId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/notes/:id/edit',
      pageBuilder: (context, state) =>
          _page(state, NoteEditorPage(noteId: state.pathParameters['id']!)),
    ),
    _route('/tasks', const TaskPage()),
    _route('/calendar', const CalendarPage()),
    _route('/ai', const AiPage()),
    _route('/ai/chat', const AiChatPage()),
    _route('/ai/task', const AiGenerateTaskPage()),
    _route('/ai/note', const AiGenerateNotePage()),
    _route('/achievement', const AchievementPage()),
    _route('/archive', const ArchivePage()),
    _route('/profile', const ProfilePage()),
    _route('/profile/ai-settings', const AiSettingsPage()),
    _route('/profile/provider-guide', const ProviderGuidePage()),
    _route('/profile/trash', const TrashPage()),
  ],
);

GoRoute _route(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _page(state, child),
  );
}

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  final path = state.uri.path;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isMobile = MediaQuery.sizeOf(context).width < 600;
      if (isMobile) {
        return _MobilePageTransition(
          animation: animation,
          axis: _isPrimaryDestination(path)
              ? AxisDirection.left
              : AxisDirection.up,
          child: child,
        );
      }

      if (_isPrimaryDestination(path)) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        );
      }

      if (_isInputFlow(path)) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          fillColor: Colors.transparent,
          child: child,
        );
      }

      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Colors.transparent,
        child: child,
      );
    },
  );
}

class _MobilePageTransition extends StatelessWidget {
  const _MobilePageTransition({
    required this.animation,
    required this.axis,
    required this.child,
  });

  final Animation<double> animation;
  final AxisDirection axis;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: _mobileBeginOffset(axis),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

Offset _mobileBeginOffset(AxisDirection axis) {
  return switch (axis) {
    AxisDirection.up => const Offset(0, 0.10),
    AxisDirection.down => const Offset(0, -0.10),
    AxisDirection.left => const Offset(0.10, 0),
    AxisDirection.right => const Offset(-0.10, 0),
  };
}

bool _isPrimaryDestination(String path) {
  return const {'/home', '/notes', '/ai', '/tasks', '/calendar'}.contains(path);
}

bool _isInputFlow(String path) {
  return path == '/notes/new' ||
      path.startsWith('/notes/') ||
      path.startsWith('/ai/') ||
      path.startsWith('/profile/');
}
