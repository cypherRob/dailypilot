import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dailypilot/shared/models/task_model.dart';
import 'package:dailypilot/shared/models/note_model.dart';
import 'package:dailypilot/shared/models/habit_model.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/shared/models/budget_model.dart';
import 'package:dailypilot/shared/models/subscription_model.dart';
import 'package:dailypilot/shared/models/goal_model.dart';
final localDbProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar is not initialized yet');
});

class LocalDb {
  static late Isar instance;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    instance = await Isar.open([
      TaskModelSchema,
      NoteModelSchema,
      HabitModelSchema,
      ExpenseModelSchema,
      BudgetModelSchema,
      SubscriptionModelSchema,
      GoalModelSchema,
    ], directory: dir.path);
  }
}
