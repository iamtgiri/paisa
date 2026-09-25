import '../models/transaction.dart';

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
  /// Keywords to classify transactions into 50/30/20 buckets
  static const Set<String> _needsKeywords = {
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
    'education'
  };

  static const Set<String> _savingsKeywords = {
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
    'ppf'
  };

  static FinancialHealthResult analyze({
    required List<Transaction> transactions,
    required double monthlyIncome,
    required double spendingLimit,
  }) {
    double needs = 0;
    double wants = 0;
    double savings = 0;
    double totalExpense = 0;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day.clamp(1, daysInMonth);

    for (final t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
        final name = t.categoryName.toLowerCase();
        final desc = t.description.toLowerCase();

        if (_savingsKeywords.any((k) => name.contains(k) || desc.contains(k))) {
          savings += t.amount;
        } else if (_needsKeywords
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

    // Daily burn rate & month-end projection
    final dailyBurnRate = currentDay > 0 ? totalExpense / currentDay : 0.0;
    final projectedMonthEndExpense = dailyBurnRate * daysInMonth;

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

    // 3. Limit Adherence (up to 30 pts)
    if (spendingLimit > 0) {
      final limitUsage = totalExpense / spendingLimit;
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
