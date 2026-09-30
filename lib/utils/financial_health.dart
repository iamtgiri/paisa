import '../models/transaction.dart';
import 'financial_insights.dart';

class FinancialHealthResult {
  final int score; // 0 to 100
  final String status;
  final String tip;
  final double needsExpense;
  final double wantsExpense;
  final double savingsExpense;
  final double totalExpense;
  final double needsRatio; // e.g. 0.50
  final double wantsRatio; // e.g. 0.30
  final double savingsRatio; // e.g. 0.20
  final double projectedMonthEndExpense;
  final double dailyBurnRate;

  const FinancialHealthResult({
    required this.score,
    required this.status,
    required this.tip,
    required this.needsExpense,
    required this.wantsExpense,
    required this.savingsExpense,
    required this.totalExpense,
    required this.needsRatio,
    required this.wantsRatio,
    required this.savingsRatio,
    required this.projectedMonthEndExpense,
    required this.dailyBurnRate,
  });
}

class FinancialHealthEngine {
  /// Keywords to classify transactions into 50/30/20 buckets.
  /// Shown to users via the Financial Health info popup — keep in sync.
  static const Set<String> needsKeywords = {
    'rent',
    'groceries',
    'electricity',
    'water bill',
    'gas',
    'cooking',
    'fuel',
    'cab',
    'auto',
    'commute',
    'loan',
    'emi',
    'credit card',
    'medical',
    'medicines',
    'insurance',
    'recharge',
    'mobile',
    'internet',
    'child care',
    'education',
    'maintenance',
    'repairs',
    'domestic help',
  };

  static const Set<String> savingsKeywords = {
    'sip',
    'mutual fund',
    'stocks',
    'trading',
    'savings',
    'deposit',
    'investment',
    'gold',
    'pension',
    'epf',
    'ppf',
    'emergency fund',
  };

  static FinancialHealthResult analyze({
    required List<Transaction> transactions,
    required double monthlyIncome,
    required double spendingLimit,
    required DateTime month,
    List<double> historicalMonthlyExpenses = const [],
  }) {
    double needs = 0;
    double wants = 0;
    double savings = 0;
    double totalExpense = 0;

    for (final t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
        final name = t.categoryName.toLowerCase();
        final desc = t.description.toLowerCase();

        if (savingsKeywords.any((k) => name.contains(k) || desc.contains(k))) {
          savings += t.amount;
        } else if (needsKeywords
            .any((k) => name.contains(k) || desc.contains(k))) {
          needs += t.amount;
        } else {
          wants += t.amount;
        }
      }
    }

    final double denominator = totalExpense > 0 ? totalExpense : 1.0;
    final needsRatio = needs / denominator;
    final wantsRatio = wants / denominator;
    final savingsRatio = savings / denominator;

    // Outlier-resistant month-end projection (shared with dashboard/reports).
    final burnRate = FinancialInsights.calculateBurnRate(
      expense: totalExpense,
      month: month,
      now: DateTime.now(),
      spendingLimit: spendingLimit > 0 ? spendingLimit : null,
      historicalMonthlyExpenses: historicalMonthlyExpenses,
    );
    final projectedMonthEndExpense = burnRate.projectedExpense;
    final dailyBurnRate = burnRate.dailyRate;

    // Financial Health Score calculation
    double scoreAcc = 0.0;

    // 1. Savings Rate Score (up to 35 pts)
    final double netSaved =
        monthlyIncome > 0 ? (monthlyIncome - totalExpense) : 0;
    final double netSavingsRatio =
        monthlyIncome > 0 ? (netSaved / monthlyIncome).clamp(0.0, 1.0) : 0;
    scoreAcc += (netSavingsRatio / 0.20 * 35).clamp(0.0, 35.0);

    // 2. 50/30/20 Rule Adherence (up to 35 pts)
    // Needs target <= 50%
    final needsPenalty = (needsRatio - 0.50).clamp(0.0, 0.50);
    scoreAcc += (20.0 - needsPenalty * 40).clamp(0.0, 20.0);

    // Wants target <= 30%
    final wantsPenalty = (wantsRatio - 0.30).clamp(0.0, 0.50);
    scoreAcc += (15.0 - wantsPenalty * 30).clamp(0.0, 15.0);

    // 3. Limit Adherence (up to 30 pts) — uses the projected month-end
    // expense so early-month scores aren't misleadingly optimistic.
    // Falls back to a soft limit from recent history when no explicit
    // spending limit is set, instead of a flat default.
    final effectiveLimit = spendingLimit > 0
        ? spendingLimit
        : FinancialInsights.calculateRobustBaseline(historicalMonthlyExpenses)
            ?.let((baseline) => baseline * 1.15);
    if (effectiveLimit != null && effectiveLimit > 0) {
      final limitUsage = projectedMonthEndExpense / effectiveLimit;
      if (limitUsage <= 0.8) {
        scoreAcc += 30.0;
      } else if (limitUsage <= 1.0) {
        scoreAcc += 20.0;
      } else {
        scoreAcc += 5.0;
      }
    } else {
      scoreAcc += 20.0;
    }

    final int finalScore = scoreAcc.round().clamp(0, 100);

    String status = 'Needs Attention';
    String tip =
        'Try cutting discretionary spends to increase your savings buffer.';
    if (finalScore >= 80) {
      status = 'Excellent';
      tip =
          'Outstanding financial discipline! You maintain a great savings balance.';
    } else if (finalScore >= 60) {
      status = 'Good';
      tip =
          'Solid expense control. Consider allocating slightly more to investments.';
    } else if (finalScore >= 40) {
      status = 'Fair';
      tip =
          'Your wants ratio is higher than recommended. Keep non-essentials in check.';
    }

    return FinancialHealthResult(
      score: finalScore,
      status: status,
      tip: tip,
      needsExpense: needs,
      wantsExpense: wants,
      savingsExpense: savings,
      totalExpense: totalExpense,
      needsRatio: needsRatio,
      wantsRatio: wantsRatio,
      savingsRatio: savingsRatio,
      projectedMonthEndExpense: projectedMonthEndExpense,
      dailyBurnRate: dailyBurnRate,
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
