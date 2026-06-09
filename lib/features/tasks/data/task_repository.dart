import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/task_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';
import 'package:dailypilot/core/notifications/notification_service.dart';

part 'task_repository.g.dart';

@riverpod
class TaskRepository extends _$TaskRepository {
  @override
  Stream<List<TaskModel>> build() {
    final isar = ref.watch(localDbProvider);
    return isar.taskModels.where().watch(fireImmediately: true);
  }

  Future<void> addTask(String title, {DateTime? reminderTime}) async {
    final isar = ref.read(localDbProvider);
    final task = TaskModel()
      ..title = title
      ..reminderTime = reminderTime
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
    });

    if (reminderTime != null) {
      NotificationService().scheduleTaskAlarm(
        id: task.id,
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: reminderTime,
      );
    }
  }

  Future<void> toggleTaskCompletion(TaskModel task, bool isCompleted) async {
    final isar = ref.read(localDbProvider);

    task
      ..isCompleted = isCompleted
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.pendingUpdate;

    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
    });
  }
}
