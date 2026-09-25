import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/utils/financial_insights.dart';

void main() {
  test('projects current-month spending from elapsed days', () {
    final result = FinancialInsights.calculateBurnRate(
      expense: 850,
      month: DateTime(2026, 9),
      now: DateTime(2026, 9, 10),
      spendingLimit: 26000,
    );

    expect(result.dailyRate, 85);
    expect(result.projectedExpense, closeTo(2550, 0.001));
    expect(result.limitDifference, closeTo(-23450, 0.001));
    expect(result.isOverLimit, isFalse);
  });

  test('does not project completed months', () {
    final result = FinancialInsights.calculateBurnRate(
      expense: 12000,
      month: DateTime(2026, 8),
      now: DateTime(2026, 9, 10),
      spendingLimit: 10000,
    );

    expect(result.dailyRate, closeTo(387.09677, 0.00001));
    expect(result.projectedExpense, 12000);
    expect(result.limitDifference, 2000);
    expect(result.isOverLimit, isTrue);
  });

  test('blends early-month spending with the historical baseline', () {
    final result = FinancialInsights.calculateBurnRate(
      expense: 1000,
      month: DateTime(2026, 9),
      now: DateTime(2026, 9, 1),
      historicalMonthlyExpenses: [14000, 15000, 16000],
    );

    expect(result.projectedExpense, greaterThan(4000));
    expect(result.projectedExpense, lessThan(10000));
  });

  test('limits the effect of an exceptional historical month', () {
    final baseline = FinancialInsights.calculateRobustBaseline(
      [10000, 11000, 12000, 100000],
    );

    expect(baseline, isNotNull);
    expect(baseline!, lessThan(20000));
  });

  test('weights recent historical months more heavily', () {
    final olderFirst = FinancialInsights.calculateRobustBaseline(
      [8000, 9000, 10000],
    );
    final recentHigh = FinancialInsights.calculateRobustBaseline(
      [8000, 9000, 14000],
    );

    expect(recentHigh, greaterThan(olderFirst!));
  });

  test('falls back to current pace when no history exists', () {
    final result = FinancialInsights.calculateBurnRate(
      expense: 700,
      month: DateTime(2026, 9),
      now: DateTime(2026, 9, 2),
    );

    expect(result.projectedExpense, closeTo(3000, 0.001));
  });
}
