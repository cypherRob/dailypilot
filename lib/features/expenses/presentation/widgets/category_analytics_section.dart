import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';
import 'package:dailypilot/features/expenses/data/expense_repository.dart';
import 'package:dailypilot/shared/models/expense_model.dart';

class CategoryAnalyticsSection extends ConsumerWidget {
  const CategoryAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseRepositoryProvider);
    final currencyState = ref.watch(currencyServiceProvider);
    final baseCurrency = currencyState.selectedCurrency;
    final currencyService = ref.watch(currencyServiceProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Analytics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        expensesAsync.when(
          data: (expenses) {
            final now = DateTime.now();
            final monthlyExpenses = expenses
                .where(
                  (e) =>
                      e.type == ExpenseType.expense &&
                      e.date.year == now.year &&
                      e.date.month == now.month,
                )
                .toList();

            if (monthlyExpenses.isEmpty) {
              return const Center(child: Text('No expenses this month.'));
            }

            final Map<ExpenseCategory, double> categoryTotals = {};
            double totalSpent = 0.0;

            for (var expense in monthlyExpenses) {
              final amount = currencyService.convert(
                expense.amount,
                expense.currency,
              );
              categoryTotals[expense.category] =
                  (categoryTotals[expense.category] ?? 0.0) + amount;
              totalSpent += amount;
            }

            final sortedCategories = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedCategories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final percentage = (entry.value / totalSpent);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '$baseCurrency ${entry.value.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(1)}%)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      minHeight: 4,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Error loading analytics')),
        ),
      ],
    );
  }
}
