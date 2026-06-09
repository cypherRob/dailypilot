import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/gemini_service.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/create_expense_dialog.dart';

void showNlpInputSheet(BuildContext context, WidgetRef ref) {
  final textController = TextEditingController();
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Smart Input',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Received 50000 INR allowance this month',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (textController.text.trim().isEmpty) return;
                      setState(() => isLoading = true);

                      try {
                        final gemini = ref.read(geminiServiceProvider);
                        final result = await gemini.parseNaturalLanguage(
                          textController.text,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        final catStr = result['category']
                            ?.toString()
                            .toLowerCase();
                        final category = ExpenseCategory.values.firstWhere(
                          (e) => e.name == catStr,
                          orElse: () => ExpenseCategory.other,
                        );
                        final typeStr = result['type']
                            ?.toString()
                            .toLowerCase();
                        final type = ExpenseType.values.firstWhere(
                          (e) => e.name == typeStr,
                          orElse: () => ExpenseType.expense,
                        );

                        showCreateExpenseDialog(
                          context,
                          ref,
                          initialAmount: (result['amount'] as num?)?.toDouble(),
                          initialCurrency: result['currency']?.toString(),
                          initialCategory: category,
                          initialType: type,
                          initialNote: result['note']?.toString(),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to parse: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Parse Transaction'),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}
