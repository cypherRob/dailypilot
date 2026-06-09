import 'package:dailypilot/features/expenses/data/currency_service.dart';
import 'package:dailypilot/features/expenses/data/expense_repository.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ExpenseInsightsSection extends ConsumerWidget {
  const ExpenseInsightsSection({super.key});

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
          'Expense Insights',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        expensesAsync.when(
          data: (transactions) {
            final expenses = transactions
                .where((transaction) => transaction.type == ExpenseType.expense)
                .toList();

            if (expenses.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No expenses to analyze yet.'),
                ),
              );
            }

            final highest = [...expenses]
              ..sort(
                (a, b) => currencyService
                    .convert(b.amount, b.currency)
                    .compareTo(currencyService.convert(a.amount, a.currency)),
              );

            final recurring = _findRecurringExpenses(expenses, currencyService);

            return Column(
              children: [
                _InsightList(
                  title: 'Highest Expenses',
                  emptyText: 'No expenses to rank yet.',
                  items: highest.take(3).map((expense) {
                    return _InsightItem(
                      label: expense.note?.isNotEmpty == true
                          ? expense.note!
                          : expense.category.name,
                      detail: DateFormat('MMM d').format(expense.date),
                      amount:
                          '$baseCurrency ${currencyService.convert(expense.amount, expense.currency).toStringAsFixed(2)}',
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _InsightList(
                  title: 'Often Recurring',
                  emptyText: 'Repeat a few expenses and they will show here.',
                  items: recurring.map((item) {
                    return _InsightItem(
                      label: item.label,
                      detail: '${item.count} times',
                      amount:
                          '$baseCurrency ${item.total.toStringAsFixed(2)} total',
                    );
                  }).toList(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Error loading insights')),
        ),
      ],
    );
  }

  List<_RecurringExpense> _findRecurringExpenses(
    List<ExpenseModel> expenses,
    CurrencyService currencyService,
  ) {
    final groups = <String, _RecurringExpense>{};

    for (final expense in expenses) {
      final label = _normalizedExpenseLabel(expense);
      final existing = groups[label];
      final amount = currencyService.convert(expense.amount, expense.currency);

      if (existing == null) {
        groups[label] = _RecurringExpense(
          label: label,
          count: 1,
          total: amount,
        );
      } else {
        existing
          ..count += 1
          ..total += amount;
      }
    }

    final recurring = groups.values.where((item) => item.count > 1).toList()
      ..sort((a, b) {
        final countComparison = b.count.compareTo(a.count);
        if (countComparison != 0) return countComparison;
        return b.total.compareTo(a.total);
      });

    return recurring.take(3).toList();
  }

  String _normalizedExpenseLabel(ExpenseModel expense) {
    final note = expense.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note.toLowerCase();
    }
    return expense.category.name;
  }
}

class _InsightList extends StatelessWidget {
  const _InsightList({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<_InsightItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else
            ...items.map((item) => _InsightRow(item: item)),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.item});

  final _InsightItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  item.detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              item.amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem {
  const _InsightItem({
    required this.label,
    required this.detail,
    required this.amount,
  });

  final String label;
  final String detail;
  final String amount;
}

class _RecurringExpense {
  _RecurringExpense({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  int count;
  double total;
}
