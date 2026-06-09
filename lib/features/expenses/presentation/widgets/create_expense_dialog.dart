import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/expense_repository.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';
import 'package:intl/intl.dart';

void showCreateExpenseDialog(
  BuildContext context,
  WidgetRef ref, {
  double? initialAmount,
  String? initialNote,
  ExpenseCategory? initialCategory,
  String? initialCurrency,
  ExpenseType initialType = ExpenseType.expense,
  DateTime? initialDate,
}) {
  final amountController = TextEditingController(
    text: initialAmount?.toString() ?? '',
  );
  final noteController = TextEditingController(text: initialNote ?? '');

  final baseCurrency = ref.read(currencyServiceProvider).selectedCurrency;
  String selectedCurrency = initialCurrency ?? baseCurrency;
  ExpenseCategory selectedCategory = initialCategory ?? ExpenseCategory.other;
  ExpenseType selectedType = initialType;
  DateTime selectedDate = initialDate ?? DateTime.now();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Transaction'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<ExpenseType>(
                    segments: const [
                      ButtonSegment(
                        value: ExpenseType.expense,
                        icon: Icon(Icons.arrow_upward),
                        label: Text('Expense'),
                      ),
                      ButtonSegment(
                        value: ExpenseType.income,
                        icon: Icon(Icons.arrow_downward),
                        label: Text('Income'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setState(() => selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: selectedCurrency,
                        items: CurrencyService.supportedCurrencies.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => selectedCurrency = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ExpenseCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Transaction month'),
                    subtitle: Text(
                      DateFormat('MMMM yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                      );
                      if (pickedDate != null) {
                        setState(() => selectedDate = pickedDate);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    ref
                        .read(expenseRepositoryProvider.notifier)
                        .addExpense(
                          amount: amount,
                          note: noteController.text,
                          category: selectedCategory,
                          type: selectedType,
                          currency: selectedCurrency,
                          date: selectedDate,
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
