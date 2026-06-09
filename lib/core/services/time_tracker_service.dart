import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _timeSpentKey = 'total_time_spent_seconds';

final timeTrackerProvider = NotifierProvider<TimeTrackerNotifier, int>(() {
  return TimeTrackerNotifier();
});

class TimeTrackerNotifier extends Notifier<int> with WidgetsBindingObserver {
  Timer? _timer;
  SharedPreferences? _prefs;
  bool _isInit = false;

  @override
  int build() {
    if (!_isInit) {
      _init();
      _isInit = true;
    }
    return 0; // Returns 0 initially, updates asynchronously
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getInt(_timeSpentKey) ?? 0;

    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state + 1;
      // Save periodically to avoid losing data if app crashes
      if (state % 10 == 0) {
        _prefs?.setInt(_timeSpentKey, state);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _prefs?.setInt(_timeSpentKey, state);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTimer();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
  }
}
