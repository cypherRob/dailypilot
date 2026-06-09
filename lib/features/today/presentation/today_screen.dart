import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/core/network/connectivity_service.dart';
import 'package:dailypilot/features/today/data/main_focus_repository.dart';
import 'package:dailypilot/features/notes/data/note_repository.dart';
import 'package:dailypilot/features/notes/presentation/widgets/create_note_dialog.dart';
import 'package:dailypilot/features/tasks/presentation/widgets/create_task_dialog.dart';
import 'package:dailypilot/features/tasks/data/task_repository.dart';
import 'package:dailypilot/features/habits/presentation/widgets/create_habit_dialog.dart';
import 'package:dailypilot/features/habits/data/habit_repository.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/create_expense_dialog.dart';
import 'package:dailypilot/features/expenses/data/expense_repository.dart';
import 'package:dailypilot/features/expenses/presentation/expenses_dashboard_screen.dart';
import 'package:dailypilot/shared/models/habit_model.dart';
import 'package:dailypilot/shared/models/note_model.dart';
import 'package:dailypilot/shared/models/task_model.dart';
import 'package:dailypilot/features/live_rooms/data/live_profile_repository.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnlineAsync = ref.watch(connectivityServiceProvider);
    final mainFocusAsync = ref.watch(mainFocusProvider);
    final profileAsync = ref.watch(liveProfileProvider);

    final greeting = _getGreeting();
    final name = profileAsync.valueOrNull?.username.isNotEmpty == true
        ? profileAsync.value!.username
        : 'User';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Wednesday, May 27',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              // Status Indicator
              isOnlineAsync.when(
                data: (isOnline) => Row(
                  children: [
                    Icon(
                      isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline mode',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    mainFocusAsync.when(
                      data: (mainFocus) => _buildDashboardCard(
                        context,
                        'Main Focus',
                        mainFocus,
                        Icons.star,
                        onTap: () => _showEditMainFocusDialog(
                          context,
                          ref,
                          mainFocus == defaultMainFocus ? '' : mainFocus,
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                      ),
                      loading: () => _buildDashboardCard(
                        context,
                        'Main Focus',
                        '...',
                        Icons.star,
                      ),
                      error: (error, stackTrace) => _buildDashboardCard(
                        context,
                        'Main Focus',
                        'Error',
                        Icons.error,
                      ),
                    ),
                    ref
                        .watch(taskRepositoryProvider)
                        .when(
                          data: (tasks) {
                            final pendingTasks = tasks.where((t) {
                              return !t.isCompleted;
                            }).toList();

                            return _buildDashboardCard(
                              context,
                              'Tasks Today',
                              '${pendingTasks.length} Pending',
                              Icons.check_circle_outline,
                              onTap: pendingTasks.isEmpty
                                  ? null
                                  : () => _showPendingTasksSheet(
                                      context,
                                      ref,
                                      pendingTasks,
                                    ),
                              trailing: pendingTasks.isEmpty
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : const Icon(Icons.chevron_right),
                            );
                          },
                          loading: () => _buildDashboardCard(
                            context,
                            'Tasks Today',
                            '...',
                            Icons.check_circle_outline,
                          ),
                          error: (error, stackTrace) => _buildDashboardCard(
                            context,
                            'Tasks Today',
                            'Error',
                            Icons.error,
                          ),
                        ),
                    ref
                        .watch(habitRepositoryProvider)
                        .when(
                          data: (habits) {
                            final habitsToComplete = habits.where((habit) {
                              return !_isHabitCompletedToday(habit);
                            }).toList();

                            return _buildDashboardCard(
                              context,
                              'Habits',
                              '${habitsToComplete.length} to complete',
                              Icons.loop,
                              onTap: habits.isEmpty
                                  ? null
                                  : () =>
                                        _showHabitsSheet(context, ref, habits),
                              trailing: habits.isEmpty
                                  ? null
                                  : habitsToComplete.isEmpty
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : const Icon(Icons.chevron_right),
                            );
                          },
                          loading: () => _buildDashboardCard(
                            context,
                            'Habits',
                            '...',
                            Icons.loop,
                          ),
                          error: (error, stackTrace) => _buildDashboardCard(
                            context,
                            'Habits',
                            'Error',
                            Icons.error,
                          ),
                        ),
                    ref
                        .watch(expenseRepositoryProvider)
                        .when(
                          data: (expenses) {
                            final todayExpenses = expenses.where((expense) {
                              return _isSameDay(expense.date, DateTime.now());
                            }).toList();
                            final total = todayExpenses.fold(
                              0.0,
                              (sum, item) => sum + item.amount,
                            );

                            return _buildDashboardCard(
                              context,
                              'Expenses Today',
                              '\$${total.toStringAsFixed(2)}',
                              Icons.attach_money,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ExpensesDashboardScreen(),
                                  ),
                                );
                              },
                              trailing: const Icon(Icons.chevron_right),
                            );
                          },
                          loading: () => _buildDashboardCard(
                            context,
                            'Expenses Today',
                            '...',
                            Icons.attach_money,
                          ),
                          error: (error, stackTrace) => _buildDashboardCard(
                            context,
                            'Expenses Today',
                            'Error',
                            Icons.error,
                          ),
                        ),
                    ref
                        .watch(noteRepositoryProvider)
                        .when(
                          data: (notes) {
                            final todayNotes = notes.where((note) {
                              return _isSameDay(note.updatedAt, DateTime.now());
                            }).toList();

                            return _buildDashboardCard(
                              context,
                              'Notes Today',
                              '${todayNotes.length} notes',
                              Icons.note_outlined,
                              onTap: todayNotes.isEmpty
                                  ? null
                                  : () => _showNotesSheet(context, todayNotes),
                              trailing: todayNotes.isEmpty
                                  ? null
                                  : const Icon(Icons.chevron_right),
                            );
                          },
                          loading: () => _buildDashboardCard(
                            context,
                            'Notes Today',
                            '...',
                            Icons.note_outlined,
                          ),
                          error: (error, stackTrace) => _buildDashboardCard(
                            context,
                            'Notes Today',
                            'Error',
                            Icons.error,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickAddMenu(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showPendingTasksSheet(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> pendingTasks,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: pendingTasks.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pending tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              final task = pendingTasks[index - 1];
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(task.title),
                subtitle: task.description == null || task.description!.isEmpty
                    ? null
                    : Text(task.description!),
                value: task.isCompleted,
                onChanged: (value) async {
                  await ref
                      .read(taskRepositoryProvider.notifier)
                      .toggleTaskCompletion(task, value ?? false);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showEditMainFocusDialog(
    BuildContext context,
    WidgetRef ref,
    String currentFocus,
  ) {
    final controller = TextEditingController(text: currentFocus);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit main focus'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Main focus'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) async {
              await MainFocusRepository.save(controller.text);
              ref.invalidate(mainFocusProvider);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await MainFocusRepository.save(controller.text);
                ref.invalidate(mainFocusProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showHabitsSheet(
    BuildContext context,
    WidgetRef ref,
    List<HabitModel> habits,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: habits.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSheetHeader(context, 'Today habits');
              }

              final habit = habits[index - 1];
              final isCompleted = _isHabitCompletedToday(habit);

              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(habit.title),
                subtitle: Text('${habit.currentStreak} day streak'),
                value: isCompleted,
                onChanged: (value) async {
                  await ref
                      .read(habitRepositoryProvider.notifier)
                      .toggleHabitCompletionForDate(
                        habit,
                        DateTime.now(),
                        value ?? false,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }


  void _showNotesSheet(BuildContext context, List<NoteModel> notes) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: notes.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSheetHeader(context, 'Today notes');
              }

              final note = notes[index - 1];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.note_outlined),
                title: Text(note.title),
                subtitle: Text(
                  note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  bool _isHabitCompletedToday(HabitModel habit) {
    return habit.completedDates.any((completedDate) {
      return _isSameDay(completedDate, DateTime.now());
    });
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _showQuickAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Add Task'),
                onTap: () {
                  Navigator.pop(context);
                  showCreateTaskDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: const Text('Add Note'),
                onTap: () {
                  Navigator.pop(context);
                  showCreateNoteDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.loop),
                title: const Text('Add Habit'),
                onTap: () {
                  Navigator.pop(context);
                  showCreateHabitDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Add Expense'),
                onTap: () {
                  Navigator.pop(context);
                  showCreateExpenseDialog(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good night';
    }
  }
}
