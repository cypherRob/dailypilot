import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/budget_repository.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';
import 'package:dailypilot/features/expenses/data/expense_repository.dart';
import 'package:dailypilot/shared/models/expense_model.dart';

class BudgetHealthSection extends ConsumerWidget {
  const BudgetHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetRepositoryProvider);
    final expensesAsync = ref.watch(expenseRepositoryProvider);
    final currencyState = ref.watch(currencyServiceProvider);
    final baseCurrency = currencyState.selectedCurrency;
    final currencyService = ref.watch(currencyServiceProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Health',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return const Center(child: Text('No active budgets.'));
            }

            final expenses = expensesAsync.valueOrNull ?? [];
            final now = DateTime.now();
            final monthlyExpenses = expenses
                .where(
                  (e) =>
                      e.type == ExpenseType.expense &&
                      e.date.year == now.year &&
                      e.date.month == now.month,
                )
                .toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final spent = monthlyExpenses
                    .where((e) => e.category == budget.category)
                    .fold(
                      0.0,
                      (sum, e) =>
                          sum + currencyService.convert(e.amount, e.currency),
                    );

                final percentUsed = budget.amount > 0
                    ? (spent / budget.amount)
                    : 0.0;
                Color progressColor = Colors.green;
                if (percentUsed >= 0.9) {
                  progressColor = Colors.red;
                } else if (percentUsed >= 0.7) {
                  progressColor = Colors.orange;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            budget.category.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '$baseCurrency ${spent.toStringAsFixed(2)} / $baseCurrency ${budget.amount.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentUsed.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Error loading budgets')),
        ),
      ],
    );
  }
}
