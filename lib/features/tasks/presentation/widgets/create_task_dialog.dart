import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/tasks/data/task_repository.dart';

void showCreateTaskDialog(BuildContext context, WidgetRef ref) {
  final titleController = TextEditingController();
  int? selectedMinutes;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task title'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Reminder Alarm',
                  ),
                  initialValue: selectedMinutes,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('No reminder')),
                    DropdownMenuItem(value: 1, child: Text('In 1 minute')),
                    DropdownMenuItem(value: 5, child: Text('In 5 minutes')),
                    DropdownMenuItem(value: 15, child: Text('In 15 minutes')),
                    DropdownMenuItem(value: 60, child: Text('In 1 hour')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedMinutes = val;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    DateTime? reminderTime;
                    if (selectedMinutes != null) {
                      reminderTime = DateTime.now().add(
                        Duration(minutes: selectedMinutes!),
                      );
                    }
                    ref
                        .read(taskRepositoryProvider.notifier)
                        .addTask(
                          titleController.text,
                          reminderTime: reminderTime,
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
