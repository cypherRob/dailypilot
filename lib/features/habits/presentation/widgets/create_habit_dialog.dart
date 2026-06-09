import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/habits/data/habit_repository.dart';

void showCreateHabitDialog(BuildContext context, WidgetRef ref) {
  final titleController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('New Habit'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Habit name (e.g., Drink Water)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref
                    .read(habitRepositoryProvider.notifier)
                    .addHabit(titleController.text);
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
