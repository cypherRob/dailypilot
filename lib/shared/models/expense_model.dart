import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel {
  Id id = Isar.autoIncrement;

  String? userId;

  double amount = 0.0;

  @enumerated
  ExpenseCategory category = ExpenseCategory.other;

  String? note;

  late DateTime date;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;

  @enumerated
  ExpenseType type = ExpenseType.expense;

  String currency = 'USD';
}

enum ExpenseType {
  income,
  expense,
}

enum ExpenseCategory {
  food,
  transport,
  bills,
  shopping,
  school,
  work,
  health,
  entertainment,
  other,
}
