import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'habit_model.g.dart';

@collection
class HabitModel {
  Id id = Isar.autoIncrement;

  String? userId;

  late String title;

  String? icon;

  String? color;

  @enumerated
  HabitFrequency frequency = HabitFrequency.daily;

  List<DateTime> completedDates = [];

  int currentStreak = 0;

  int bestStreak = 0;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;
}

enum HabitFrequency { daily, weekly }
