import 'dart:async';

import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'expense_repository.g.dart';

@riverpod
class ExpenseRepository extends _$ExpenseRepository {
  @override
  Stream<List<ExpenseModel>> build() {
    final isar = ref.watch(localDbProvider);
    unawaited(_removeStaleRolexDemoExpense(isar));
    return isar.expenseModels.where().sortByDateDesc().watch(
      fireImmediately: true,
    );
  }

  Future<void> addExpense({
    required double amount,
    required String note,
    required ExpenseCategory category,
    ExpenseType type = ExpenseType.expense,
    String currency = 'USD',
    DateTime? date,
  }) async {
    final now = DateTime.now();
    final isar = ref.read(localDbProvider);
    final expense = ExpenseModel()
      ..amount = amount
      ..note = note
      ..category = category
      ..type = type
      ..currency = currency
      ..date = date ?? now
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.expenseModels.put(expense);
    });
  }

  Future<void> deleteExpense(Id id) async {
    final isar = ref.read(localDbProvider);
    await isar.writeTxn(() async {
      await isar.expenseModels.delete(id);
    });
  }

  Future<void> _removeStaleRolexDemoExpense(Isar isar) async {
    final staleExpenses = await isar.expenseModels
        .where()
        .filter()
        .amountEqualTo(2000)
        .and()
        .noteContains('rolex', caseSensitive: false)
        .findAll();

    if (staleExpenses.isEmpty) return;

    await isar.writeTxn(() async {
      await isar.expenseModels.deleteAll(
        staleExpenses.map((expense) => expense.id).toList(),
      );
    });
  }
}
