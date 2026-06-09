import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  String? userId; // Nullable for local users

  late String title;

  String? description;

  DateTime? dueDate;

  DateTime? reminderTime;

  @enumerated
  TaskPriority priority = TaskPriority.medium;

  bool isCompleted = false;

  @enumerated
  RepeatType repeatType = RepeatType.none;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;
}

enum TaskPriority { low, medium, high }

enum RepeatType { none, daily, weekly, monthly }
