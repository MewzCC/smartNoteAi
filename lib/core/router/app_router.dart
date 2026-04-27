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
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}
