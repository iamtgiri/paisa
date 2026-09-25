import 'dart:math' as math;

class BurnRateInsight {
  final double dailyRate;
  final double projectedExpense;
  final double? limitDifference;

  const BurnRateInsight({
    required this.dailyRate,
    required this.projectedExpense,
    required this.limitDifference,
  });

  bool get isOverLimit => limitDifference != null && limitDifference! > 0;
}

class FinancialInsights {
  /// Returns a recency-weighted baseline while limiting the influence of
  /// exceptional months with a median/MAD outlier fence.
  static double? calculateRobustBaseline(List<double> monthlyExpenses) {
    final values =
        monthlyExpenses.where((value) => value.isFinite && value >= 0).toList();
    if (values.isEmpty) return null;

    final sorted = [...values]..sort();
    final median = _median(sorted);
    final deviations = sorted.map((value) => (value - median).abs()).toList()
      ..sort();
    final mad = _median(deviations);
    final fence = mad == 0 ? 0.0 : mad * 3.0;
    final clipped = fence == 0
        ? List<double>.filled(values.length, median)
        : values
            .map((value) =>
                value.clamp(median - fence, median + fence).toDouble())
            .toList();

    var weightedTotal = 0.0;
    var weightTotal = 0.0;
    for (var index = 0; index < clipped.length; index++) {
      final age = clipped.length - index - 1;
      final weight = age == 0 ? 1.0 : 0.75 * math.pow(0.75, age - 1).toDouble();
      weightedTotal += clipped[index] * weight;
      weightTotal += weight;
    }
    return weightTotal == 0 ? median : weightedTotal / weightTotal;
  }

  static BurnRateInsight calculateBurnRate({
    required double expense,
    required DateTime month,
    required DateTime now,
    double? spendingLimit,
    double? baselineMonthlyExpense,
    List<double>? historicalMonthlyExpenses,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = now.year == month.year && now.month == month.month;
    final int daysElapsed =
        isCurrentMonth ? now.day.clamp(1, daysInMonth).toInt() : daysInMonth;
    final baseline = calculateRobustBaseline(historicalMonthlyExpenses ?? []) ??
        baselineMonthlyExpense;
    final observedDays = isCurrentMonth
        ? daysElapsed.clamp(7, daysInMonth).toDouble()
        : daysInMonth.toDouble();
    final currentProjection = expense / observedDays * daysInMonth;
    final historicalWeight = isCurrentMonth && baseline != null
        ? (0.30 * (1 - daysElapsed / daysInMonth)).clamp(0.0, 0.30).toDouble()
        : 0.0;
    final projectedExpense = isCurrentMonth && baseline != null
        ? currentProjection * (1 - historicalWeight) +
            baseline * historicalWeight
        : isCurrentMonth
            ? currentProjection
            : expense;
    final dailyRate = projectedExpense / daysInMonth;

    return BurnRateInsight(
      dailyRate: dailyRate,
      projectedExpense: projectedExpense,
      limitDifference:
          spendingLimit == null ? null : projectedExpense - spendingLimit,
    );
  }

  static double _median(List<double> sortedValues) {
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) return sortedValues[middle];
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }
}
