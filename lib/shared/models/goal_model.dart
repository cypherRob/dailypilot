import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'goal_model.g.dart';

@collection
class GoalModel {
  Id id = Isar.autoIncrement;

  String? userId;

  late String name;

  double targetAmount = 0.0;

  double currentAmount = 0.0;
  
  String currency = 'USD';

  late DateTime targetDate;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;
}
