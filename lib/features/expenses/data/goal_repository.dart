import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/goal_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'goal_repository.g.dart';

@riverpod
class GoalRepository extends _$GoalRepository {
  @override
  Stream<List<GoalModel>> build() {
    final isar = ref.watch(localDbProvider);
    return isar.goalModels.where().watch(fireImmediately: true);
  }

  Future<void> addGoal(GoalModel goal) async {
    final isar = ref.read(localDbProvider);
    goal.createdAt = DateTime.now();
    goal.updatedAt = DateTime.now();
    goal.syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.goalModels.put(goal);
    });
  }
}
