import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mainFocusKey = 'today_main_focus';
const defaultMainFocus = 'Set your main focus';

final mainFocusProvider = FutureProvider<String>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getString(_mainFocusKey) ?? defaultMainFocus;
});

class MainFocusRepository {
  static Future<void> save(String focus) async {
    final preferences = await SharedPreferences.getInstance();
    final trimmedFocus = focus.trim();

    if (trimmedFocus.isEmpty) {
      await preferences.remove(_mainFocusKey);
      return;
    }

    await preferences.setString(_mainFocusKey, trimmedFocus);
  }
}
