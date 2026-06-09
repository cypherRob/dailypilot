import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/finance_analytics_repository.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';

class FinancialHealthSection extends ConsumerWidget {
  const FinancialHealthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthScore = ref.watch(financialHealthScoreProvider);
    final incomeThisMonth = ref.watch(totalIncomeThisMonthProvider);
    final spentThisMonth = ref.watch(totalSpentThisMonthProvider);
    final currencyState = ref.watch(currencyServiceProvider);
    final baseCurrency = currencyState.selectedCurrency;

    Color scoreColor = Colors.green;
    String status = 'Excellent';

    if (healthScore < 50) {
      scoreColor = Colors.red;
      status = 'At Risk';
    } else if (healthScore < 70) {
      scoreColor = Colors.orange;
      status = 'Fair';
    } else if (healthScore < 85) {
      scoreColor = Colors.blue;
      status = 'Good';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Financial Health Score',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: healthScore / 100,
                strokeWidth: 12,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  healthScore.toString(),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'This month: $baseCurrency ${incomeThisMonth.toStringAsFixed(2)} received and $baseCurrency ${spentThisMonth.toStringAsFixed(2)} spent.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
