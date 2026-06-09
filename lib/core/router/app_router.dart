import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dailypilot/features/today/presentation/today_screen.dart';
import 'package:dailypilot/features/notes/presentation/notes_screen.dart';
import 'package:dailypilot/features/live_rooms/presentation/live_rooms_screen.dart';
import 'package:dailypilot/features/profile/presentation/profile_screen.dart';
import 'package:dailypilot/features/splash/presentation/splash_screen.dart';
import 'package:dailypilot/shared/layout/app_layout.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorTodayKey = GlobalKey<NavigatorState>(debugLabel: 'today');
final _shellNavigatorNotesKey = GlobalKey<NavigatorState>(debugLabel: 'notes');
final _shellNavigatorCommonKey = GlobalKey<NavigatorState>(
  debugLabel: 'common',
);
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'profile',
);

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTodayKey,
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorNotesKey,
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCommonKey,
            routes: [
              GoRoute(
                path: '/common',
                builder: (context, state) => const LiveRoomsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
