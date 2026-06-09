import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'subscription_model.g.dart';

@collection
class SubscriptionModel {
  Id id = Isar.autoIncrement;

  String? userId;

  late String name;

  double cost = 0.0;
  
  String currency = 'USD';

  @enumerated
  ExpenseCategory category = ExpenseCategory.bills;

  late DateTime renewalDate;

  bool isActive = true;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;
}
