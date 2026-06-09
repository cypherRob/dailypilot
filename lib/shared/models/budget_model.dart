import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'budget_model.g.dart';

@collection
class BudgetModel {
  Id id = Isar.autoIncrement;

  String? userId;

  double amount = 0.0;

  @enumerated
  ExpenseCategory category = ExpenseCategory.other;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;
}
