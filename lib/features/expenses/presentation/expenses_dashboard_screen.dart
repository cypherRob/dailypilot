import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/finance_analytics_repository.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/recent_transactions_section.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/budget_health_section.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/financial_health_section.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/category_analytics_section.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/savings_goals_carousel.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/subscription_manager_section.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/quick_actions_dock.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/expense_insights_section.dart';

class ExpensesDashboardScreen extends ConsumerWidget {
  const ExpensesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Financial OS'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final currentBase = ref.watch(
                currencyServiceProvider.select(
                  (state) => state.selectedCurrency,
                ),
              );
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentBase,
                  icon: const Icon(Icons.currency_exchange, size: 16),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref
                          .read(currencyServiceProvider.notifier)
                          .setBaseCurrency(newValue);
                    }
                  },
                  items: CurrencyService.supportedCurrencies
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeroCard(),
                const SizedBox(height: 32),
                const RecentTransactionsSection(),
                const SizedBox(height: 32),
                const BudgetHealthSection(),
                const SizedBox(height: 32),
                const FinancialHealthSection(),
                const SizedBox(height: 32),
                const CategoryAnalyticsSection(),
                const SizedBox(height: 32),
                const ExpenseInsightsSection(),
                const SizedBox(height: 32),
                const SavingsGoalsCarousel(),
                const SizedBox(height: 32),
                const SubscriptionManagerSection(),
                const SizedBox(height: 100), // padding for the dock
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(child: const QuickActionsDock()),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spentToday = ref.watch(totalSpentTodayProvider);
    final spentThisMonth = ref.watch(totalSpentThisMonthProvider);
    final incomeThisMonth = ref.watch(totalIncomeThisMonthProvider);
    final allowance = ref.watch(dailyAllowanceProvider);
    final baseCurrency = ref.watch(
      currencyServiceProvider.select((state) => state.selectedCurrency),
    );

    final remaining = incomeThisMonth - spentThisMonth;
    final isOverLimit = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent This Month',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$baseCurrency ${spentThisMonth.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Monthly Income',
                  value: '$baseCurrency ${incomeThisMonth.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'Daily Allowance',
                  value: '$baseCurrency ${allowance.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'Remaining',
                  value: '$baseCurrency ${remaining.abs().toStringAsFixed(2)}',
                  color: isOverLimit ? Colors.red : Colors.green,
                  prefix: isOverLimit ? '-' : '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: allowance > 0
                  ? (spentToday / allowance).clamp(0.0, 1.0)
                  : 0,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverLimit ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isOverLimit
                ? "You've spent more than this month's income."
                : "You have $baseCurrency ${remaining.toStringAsFixed(2)} left from this month's income.",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String prefix;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$prefix$value',
            maxLines: 1,
            style: TextStyle(
              color: color ?? Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
