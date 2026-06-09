import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/habit_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'habit_repository.g.dart';

@riverpod
class HabitRepository extends _$HabitRepository {
  @override
  Stream<List<HabitModel>> build() {
    final isar = ref.watch(localDbProvider);
    return isar.habitModels.where().watch(fireImmediately: true);
  }

  Future<void> addHabit(String title) async {
    final isar = ref.read(localDbProvider);
    final habit = HabitModel()
      ..title = title
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.habitModels.put(habit);
    });
  }

  Future<void> toggleHabitCompletionForDate(
    HabitModel habit,
    DateTime date,
    bool isCompleted,
  ) async {
    final isar = ref.read(localDbProvider);
    final day = DateTime(date.year, date.month, date.day);
    final completedDates = habit.completedDates.where((completedDate) {
      return !_isSameDay(completedDate, day);
    }).toList();

    if (isCompleted) {
      completedDates.add(day);
    }

    habit
      ..completedDates = completedDates
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.pendingUpdate;

    await isar.writeTxn(() async {
      await isar.habitModels.put(habit);
    });
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
