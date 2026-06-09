import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/budget_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'budget_repository.g.dart';

@riverpod
class BudgetRepository extends _$BudgetRepository {
  @override
  Stream<List<BudgetModel>> build() {
    final isar = ref.watch(localDbProvider);
    return isar.budgetModels.where().watch(fireImmediately: true);
  }

  Future<void> addBudget(BudgetModel budget) async {
    final isar = ref.read(localDbProvider);
    budget.createdAt = DateTime.now();
    budget.updatedAt = DateTime.now();
    budget.syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.budgetModels.put(budget);
    });
  }
}
