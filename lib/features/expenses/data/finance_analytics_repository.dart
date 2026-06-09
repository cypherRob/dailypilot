import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:dailypilot/features/expenses/data/expense_repository.dart';
import 'package:dailypilot/features/expenses/data/budget_repository.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/features/expenses/data/currency_service.dart';

part 'finance_analytics_repository.g.dart';

final totalSpentThisMonthProvider = fr.Provider<double>((ref) {
  final expenses = ref.watch(expenseRepositoryProvider).valueOrNull ?? [];
  final now = DateTime.now();
  ref.watch(currencyServiceProvider);
  final currencyService = ref.watch(currencyServiceProvider.notifier);

  return expenses
      .where(
        (e) =>
            e.type == ExpenseType.expense &&
            e.date.year == now.year &&
            e.date.month == now.month,
      )
      .fold(
        0.0,
        (sum, e) => sum + currencyService.convert(e.amount, e.currency),
      );
});

final totalIncomeThisMonthProvider = fr.Provider<double>((ref) {
  final expenses = ref.watch(expenseRepositoryProvider).valueOrNull ?? [];
  final now = DateTime.now();
  ref.watch(currencyServiceProvider);
  final currencyService = ref.watch(currencyServiceProvider.notifier);

  return expenses
      .where(
        (e) =>
            e.type == ExpenseType.income &&
            e.date.year == now.year &&
            e.date.month == now.month,
      )
      .fold(
        0.0,
        (sum, e) => sum + currencyService.convert(e.amount, e.currency),
      );
});

@riverpod
double totalSpentToday(TotalSpentTodayRef ref) {
  final expenses = ref.watch(expenseRepositoryProvider).valueOrNull ?? [];
  final today = DateTime.now();
  ref.watch(currencyServiceProvider);
  final currencyService = ref.watch(currencyServiceProvider.notifier);

  return expenses
      .where(
        (e) =>
            e.type == ExpenseType.expense &&
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day,
      )
      .fold(
        0.0,
        (sum, e) => sum + currencyService.convert(e.amount, e.currency),
      );
}

@riverpod
double totalIncomeToday(TotalIncomeTodayRef ref) {
  final expenses = ref.watch(expenseRepositoryProvider).valueOrNull ?? [];
  final today = DateTime.now();
  ref.watch(currencyServiceProvider);
  final currencyService = ref.watch(currencyServiceProvider.notifier);

  return expenses
      .where(
        (e) =>
            e.type == ExpenseType.income &&
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day,
      )
      .fold(
        0.0,
        (sum, e) => sum + currencyService.convert(e.amount, e.currency),
      );
}

@riverpod
double dailyAllowance(DailyAllowanceRef ref) {
  final budgets = ref.watch(budgetRepositoryProvider).valueOrNull ?? [];
  final incomeThisMonth = ref.watch(totalIncomeThisMonthProvider);
  final spentThisMonth = ref.watch(totalSpentThisMonthProvider);

  final totalBudget = budgets.fold(
    0.0,
    (sum, b) => sum + b.amount,
  ); // Budgets are assumed to be in Base Currency for now

  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final remainingDays = daysInMonth - now.day + 1;

  final monthlyLimit = totalBudget > 0 ? totalBudget : incomeThisMonth;
  if (monthlyLimit <= 0) return 0.0;

  final remainingBudget = monthlyLimit - spentThisMonth;
  if (remainingBudget <= 0) return 0.0;

  return remainingBudget / remainingDays;
}

@riverpod
int financialHealthScore(FinancialHealthScoreRef ref) {
  final income = ref.watch(totalIncomeThisMonthProvider);
  final spent = ref.watch(totalSpentThisMonthProvider);
  final dailyAllowance = ref.watch(dailyAllowanceProvider);
  final spentToday = ref.watch(totalSpentTodayProvider);

  if (income <= 0 && spent <= 0) return 50;
  if (income <= 0) return 20;

  final savingsRate = (income - spent) / income;
  var score = 50 + (savingsRate * (savingsRate >= 0 ? 50 : 65)).round();

  if (dailyAllowance > 0 && spentToday > dailyAllowance) {
    score -= 8;
  } else if (dailyAllowance > 0 && spentToday <= dailyAllowance) {
    score += 5;
  }

  return score.clamp(0, 100);
}
