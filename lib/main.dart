import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/core/notifications/notification_service.dart';
import 'package:dailypilot/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalDb.init();
  final prefs = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  try {
    await NotificationService().init();
    debugPrint('NotificationService initialized successfully.');
  } catch (e) {
    debugPrint('NotificationService not initialized: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        localDbProvider.overrideWithValue(LocalDb.instance),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DailyPilotApp(),
    ),
  );
}
