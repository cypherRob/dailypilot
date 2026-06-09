import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/core/router/app_router.dart';
import 'package:dailypilot/core/theme/app_theme.dart';
import 'package:dailypilot/core/services/time_tracker_service.dart';

class DailyPilotApp extends ConsumerWidget {
  const DailyPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeSettings = ref.watch(appThemeSettingsProvider);

    // Initialize time tracker on app start
    ref.watch(timeTrackerProvider);

    return MaterialApp.router(
      title: 'FiNotes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeFor(themeSettings),
      darkTheme: AppTheme.darkThemeFor(themeSettings),
      themeMode: themeSettings.themeMode,
      routerConfig: router,
    );
  }
}
