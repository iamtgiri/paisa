import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';
import '../../models/isar_service.dart';
import '../../providers/providers.dart';
import '../../models/budget.dart';
import '../../models/recurring.dart';
import '../../models/savings_goal.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../utils/financial_health.dart';
import '../../widgets/shared_widgets.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sm = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(selectedMonthProvider.notifier).state = sm.prev(),
                child: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: Text(
                  AppUtils.formatMonthYear(sm.year, sm.month),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: sm.isCurrentMonth
                    ? null
                    : () => ref.read(selectedMonthProvider.notifier).state =
                        sm.next(),
                child: Icon(Icons.chevron_right,
                    color: sm.isCurrentMonth
                        ? context.appColors.onSurfaceMuted
                        : context.appColors.onSurface),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Breakdown'),
            Tab(text: 'Trends'),
            Tab(text: 'Categories'),
            Tab(text: 'Calculator'),
            Tab(text: 'Insights'),
            Tab(text: 'Top Spends'),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: context.appColors.onSurfaceMuted,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _BreakdownTab(
            touchedIndex: _touchedPieIndex,
            onTouch: (i) => setState(() => _touchedPieIndex = i),
          ),
          const _TrendsTab(),
          const _CategoryInsightsTab(),
          const _CategoryCalculatorTab(),
          const _InsightsTab(),
          const _TopSpendsTab(),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 1 — BREAKDOWN (pie + category list + payment method)
// ════════════════════════════════════════════════════════════════
class _BreakdownTab extends ConsumerStatefulWidget {
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  const _BreakdownTab({required this.touchedIndex, required this.onTouch});

  @override
  ConsumerState<_BreakdownTab> createState() => _BreakdownTabState();
}

class _BreakdownTabState extends ConsumerState<_BreakdownTab>
    with SingleTickerProviderStateMixin {
  late TabController _typeCtrl;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TabController(length: 2, vsync: this);
    _typeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Expense / Income toggle
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _typeCtrl,
            tabs: const [Tab(text: 'Expenses'), Tab(text: 'Income')],
            labelColor: context.appColors.onSurface,
            unselectedLabelColor: context.appColors.onSurfaceMuted,
            indicator: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _typeCtrl,
            children: [
              _buildCategoryBreakdown(TransactionType.expense),
              _buildCategoryBreakdown(TransactionType.income),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(TransactionType type) {
    final totalsAsync = type == TransactionType.expense
        ? ref.watch(expenseCategoryTotalsProvider)
        : ref.watch(incomeCategoryTotalsProvider);

    return totalsAsync.when(
      data: (totals) {
        if (totals.isEmpty) {
          return EmptyState(
            icon: Icons.pie_chart_outline,
            title: 'No data this month',
            subtitle: 'Add some transactions to see analytics',
          );
        }
        final sorted = totals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = sorted.fold<double>(0, (s, e) => s + e.value);
        final colors = AppUtils.chartColors;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pie chart card
            _PieChartCard(
              sorted: sorted,
              total: total,
              colors: colors,
              type: type,
              touchedIndex: widget.touchedIndex,
              onTouch: widget.onTouch,
            ),
            const SizedBox(height: 12),
            // Category rows
            ...sorted.asMap().entries.map((e) {
              final pct = total > 0 ? e.value.value / total * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CategoryRow(
                  name: e.value.key,
                  amount: e.value.value,
                  percent: pct,
                  color: _analyticsChartColor(colors, e.key),
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildPaymentBreakdown(type),
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => const ShimmerList(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPaymentBreakdown(TransactionType type) {
    final txnsAsync = ref.watch(monthlyTransactionsProvider);
    final accounts = ref.watch(accountsProvider);
    return txnsAsync.when(
      data: (txns) {
        final filtered = txns.where((t) => t.type == type).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();

        final pmTotals = <({String key, String label, double amount})>[];
        for (final t in filtered) {
          String label = AppUtils.paymentMethodLabel(t.paymentMethod);
          if (t.paymentAccountId != null) {
            for (final account in accounts) {
              if (account.id == t.paymentAccountId) {
                label = account.name;
                break;
              }
            }
          }
          final key = t.paymentAccountId ?? 'method:${t.paymentMethod.name}';
          final existingIndex = pmTotals.indexWhere((e) => e.key == key);
          if (existingIndex >= 0) {
            final existing = pmTotals[existingIndex];
            pmTotals[existingIndex] = (
              key: existing.key,
              label: existing.label,
              amount: existing.amount + t.amount,
            );
          } else {
            pmTotals.add((key: key, label: label, amount: t.amount));
          }
        }
        final total = pmTotals.fold<double>(0, (s, v) => s + v.amount);
        final sorted = [...pmTotals]
          ..sort((a, b) => b.amount.compareTo(a.amount));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By Account',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurface)),
              const SizedBox(height: 12),
              ...sorted.map((e) {
                final pct = total > 0 ? e.amount / total * 100 : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(e.label,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.appColors.onSurface),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: context.appColors.surfaceCard2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.onSurfaceMuted,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 2 — TRENDS (6-month line chart + daily bar)
// ════════════════════════════════════════════════════════════════
class _TrendsTab extends ConsumerWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlyTrendProvider);
    final dailyAsync = ref.watch(dailyTotalsProvider);
    final sm = ref.watch(selectedMonthProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 6-month line chart
        trendAsync.when(
          data: (trend) => _buildTrendChart(context, trend),
          loading: () => Container(
            height: 220,
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SizedBox(height: 16),
        // Daily bar chart
        dailyAsync.when(
          data: (daily) => _buildDailyChart(context, daily, sm),
          loading: () => Container(
            height: 180,
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        // Daily spending heatmap
        dailyAsync.when(
          data: (daily) => _buildHeatmap(context, daily, sm),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHeatmap(
      BuildContext context, Map<int, double> daily, SelectedMonth sm) {
    if (daily.isEmpty) return const SizedBox.shrink();

    final daysInMonth = DateTime(sm.year, sm.month + 1, 0).day;
    final firstWeekday = DateTime(sm.year, sm.month, 1).weekday; // 1=Mon
    final leadingBlanks = firstWeekday - 1;
    final maxValue = daily.values.isEmpty
        ? 0.0
        : daily.values.reduce((a, b) => a > b ? a : b);
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily spending heatmap',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: weekdayLabels
                .map((label) => Expanded(
                      child: Center(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 10,
                                color: context.appColors.onSurfaceMuted)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final value = daily[day] ?? 0;
              final intensity = maxValue > 0 ? (value / maxValue) : 0.0;
              final color = value > 0
                  ? AppTheme.primary
                      .withOpacity((0.15 + intensity * 0.85).clamp(0.15, 1.0))
                  : context.appColors.surfaceCard2;
              return GestureDetector(
                onTap: value > 0
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Day $day: ${AppUtils.formatAmount(value)}'),
                            duration: const Duration(seconds: 2),
                          ),
                        )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: intensity > 0.5
                            ? Colors.white
                            : context.appColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    List<({int year, int month, double expense, double income})> trend,
  ) {
    if (trend.every((t) => t.expense == 0 && t.income == 0)) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const EmptyState(
          icon: Icons.show_chart,
          title: 'Not enough data',
          subtitle: 'Add transactions across multiple months to see trends',
        ),
      );
    }

    final maxValue = trend.fold<double>(
      0,
      (m, t) => [m, t.expense, t.income].reduce((a, b) => a > b ? a : b),
    );
    final maxY = maxValue > 0 ? maxValue * 1.2 : 10000.0;

    final expenseSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.expense);
    }).toList();

    final incomeSpots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.income);
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6-Month Overview',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurface)),
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(context, AppTheme.expense, 'Expense'),
              const SizedBox(width: 16),
              _legendDot(context, AppTheme.income, 'Income'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (trend.length - 1).toDouble(),
                maxY: maxY,
                minY: 0,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 2500,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: context.appColors.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: trend.length > 4 ? 1 : null,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        final t = trend[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM').format(DateTime(t.year, t.month)),
                            style: TextStyle(
                                fontSize: 9,
                                color: context.appColors.onSurfaceMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => context.appColors.surfaceCard2,
                    getTooltipItems: (spots) => spots.map((s) {
                      final color =
                          s.barIndex == 0 ? AppTheme.expense : AppTheme.income;
                      final label = s.barIndex == 0 ? 'Exp' : 'Inc';
                      return LineTooltipItem(
                        '$label: ${AppUtils.formatAmount(s.y, compact: true)}',
                        TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  // Expense line
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.expense,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.expense,
                        strokeWidth: 1.5,
                        strokeColor: context.appColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.expense.withOpacity(0.06),
                    ),
                  ),
                  // Income line
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.income,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppTheme.income,
                        strokeWidth: 1.5,
                        strokeColor: context.appColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.income.withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Month-by-month summary rows below chart
          const SizedBox(height: 16),
          ...trend.reversed.take(3).map((t) {
            final savings = t.income > 0
                ? ((t.income - t.expense) / t.income * 100).clamp(-999.0, 100.0)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      DateFormat('MMM').format(DateTime(t.year, t.month)),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.onSurfaceMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        _trendCell(
                            AppUtils.formatAmount(t.expense, compact: true),
                            AppTheme.expense),
                        _trendCell(
                            AppUtils.formatAmount(t.income, compact: true),
                            AppTheme.income),
                        _trendCell(
                            '${savings.toStringAsFixed(0)}% saved',
                            savings >= 20
                                ? AppTheme.income
                                : savings >= 0
                                    ? Colors.orange
                                    : AppTheme.expense),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _trendCell(String text, Color color) {
    return Expanded(
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.appColors.onSurfaceMuted)),
      ],
    );
  }

  Widget _buildDailyChart(
    BuildContext context,
    Map<int, double> daily,
    SelectedMonth sm,
  ) {
    if (daily.isEmpty) return const SizedBox.shrink();
    final daysInMonth = DateTime(sm.year, sm.month + 1, 0).day;
    final maxVal = daily.values.fold<double>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Spending',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.25 : 1000,
                barGroups: List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final val = daily[day] ?? 0;
                  return BarChartGroupData(
                    x: day,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: val > 0
                            ? AppTheme.expense.withOpacity(0.75)
                            : context.appColors.surfaceCard2,
                        width: 5,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (v, _) {
                        if (v % 5 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${v.toInt()}',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: context.appColors.onSurfaceMuted)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? maxVal / 3 : 1000,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: context.appColors.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.appColors.surfaceCard2,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      'Day ${group.x}\n${AppUtils.formatAmount(rod.toY, compact: true)}',
                      TextStyle(
                          fontSize: 10, color: context.appColors.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 3 — CATEGORY INSIGHTS
// ════════════════════════════════════════════════════════════════
double _readCategoryAmount(Map<String, double> totals, String name) {
  // Older/restored records can contain whole-number totals at runtime.
  final value = (totals as dynamic)[name];
  return value is num ? value.toDouble() : 0.0;
}

class _CategoryInsightsTab extends ConsumerWidget {
  const _CategoryInsightsTab();

  Future<void> _showCategoryDetail(BuildContext context, String categoryName,
      List<({int year, int month, Map<String, double> totals})> months) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryHistorySheet(
        categoryName: categoryName,
        months: months,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(expenseCategoryTrendProvider);
    final sm = ref.watch(selectedMonthProvider);

    return trendAsync.when(
      data: (months) {
        if (months.isEmpty) {
          return const EmptyState(
            icon: Icons.insights_outlined,
            title: 'No category history',
            subtitle: 'Add expenses to compare category performance',
          );
        }
        final current = months.last.totals;
        final Map<String, double> previous = months.length > 1
            ? months[months.length - 2].totals
            : <String, double>{};
        final names = <String>{...current.keys, ...previous.keys};
        for (final month in months) {
          names.addAll(month.totals.keys);
        }
        final categories = names.toList()
          ..sort((a, b) => _readCategoryAmount(current, b)
              .compareTo(_readCategoryAmount(current, a)));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Text('Category performance',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                months.length > 1
                    ? 'This month compared with ${DateFormat('MMMM').format(DateTime(
                        months[months.length - 2].year,
                        months[months.length - 2].month,
                      ))}'
                    : 'Tap a category to view its history',
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted)),
            const SizedBox(height: 16),
            ...categories.map((name) {
              final amount = _readCategoryAmount(current, name);
              final prior = _readCategoryAmount(previous, name);
              final average = months
                      .map((month) => _readCategoryAmount(month.totals, name))
                      .reduce((a, b) => a + b) /
                  months.length;
              return _CategoryInsightCard(
                name: name,
                amount: amount,
                previousAmount: prior,
                average: average,
                monthLabel:
                    DateFormat('MMM').format(DateTime(sm.year, sm.month)),
                onTap: () => _showCategoryDetail(context, name, months),
              );
            }),
          ],
        );
      },
      loading: () => const ShimmerList(),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _CategoryInsightCard extends StatelessWidget {
  final String name;
  final double amount;
  final double previousAmount;
  final double average;
  final String monthLabel;
  final VoidCallback onTap;

  const _CategoryInsightCard({
    required this.name,
    required this.amount,
    required this.previousAmount,
    required this.average,
    required this.monthLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final difference = amount - previousAmount;
    final percentage = previousAmount == 0
        ? (amount > 0 ? 100.0 : 0.0)
        : difference / previousAmount * 100;
    final isImprovement = difference <= 0;
    final accent = isImprovement ? AppTheme.income : AppTheme.expense;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(AppUtils.formatAmount(amount, compact: true),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isImprovement
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      previousAmount == 0
                          ? (amount == 0 ? 'No spending' : 'New spending')
                          : '${percentage.abs().toStringAsFixed(0)}% ${isImprovement ? 'lower' : 'higher'} than last month',
                      style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                        '6-mo avg ${AppUtils.formatAmount(average, compact: true)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: context.appColors.onSurfaceMuted)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                    '$monthLabel: current · last month: ${AppUtils.formatAmount(previousAmount, compact: true)}',
                    style: TextStyle(
                        fontSize: 10, color: context.appColors.onSurfaceMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryHistorySheet extends StatelessWidget {
  final String categoryName;
  final List<({int year, int month, Map<String, double> totals})> months;

  const _CategoryHistorySheet({
    required this.categoryName,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    final values = months
        .map((month) => _readCategoryAmount(month.totals, categoryName))
        .toList();
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final average = values.isEmpty ? 0.0 : total / values.length;
    final maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final minValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final maxIndex = values.indexOf(maxValue);
    final minIndex = values.indexOf(minValue);
    final current = values.isEmpty ? 0.0 : values.last;
    final previous = values.length > 1 ? values[values.length - 2] : 0.0;
    final change = previous == 0
        ? (current > 0 ? null : 0.0)
        : (current - previous) / previous * 100;

    return Container(
      constraints: const BoxConstraints(maxHeight: 680),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(categoryName,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text('Six-month spending history',
                  style: TextStyle(
                      fontSize: 12, color: context.appColors.onSurfaceMuted)),
              const SizedBox(height: 16),
              _CategoryHistoryStats(
                current: current,
                average: average,
                total: total,
                change: change,
              ),
              const SizedBox(height: 16),
              _CategoryHistoryChart(months: months, values: values),
              const SizedBox(height: 16),
              Text('MONTH-BY-MONTH',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurfaceMuted,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ...months.asMap().entries.toList().reversed.map((entry) {
                final index = entry.key;
                final month = entry.value;
                final amount = values[index];
                return _CategoryMonthRow(
                  label: DateFormat('MMMM yyyy')
                      .format(DateTime(month.year, month.month)),
                  amount: amount,
                  isHighest: index == maxIndex,
                  isLowest: index == minIndex && minValue < maxValue,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHistoryStats extends StatelessWidget {
  final double current;
  final double average;
  final double total;
  final double? change;

  const _CategoryHistoryStats({
    required this.current,
    required this.average,
    required this.total,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor = change == null
        ? AppTheme.primary
        : change! <= 0
            ? AppTheme.income
            : AppTheme.expense;
    final changeLabel = change == null
        ? 'New spending'
        : '${change!.abs().toStringAsFixed(0)}% vs last month';
    return Row(
      children: [
        Expanded(
            child:
                _historyStat(context, 'This month', current, AppTheme.primary)),
        Expanded(
            child:
                _historyStat(context, '6-mo average', average, Colors.orange)),
        Expanded(
            child:
                _historyStat(context, '6-mo total', total, AppTheme.expense)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trend',
                  style: TextStyle(
                      fontSize: 10, color: context.appColors.onSurfaceMuted)),
              const SizedBox(height: 4),
              Text(changeLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: changeColor),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _historyStat(
      BuildContext context, String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.appColors.onSurfaceMuted),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(AppUtils.formatAmount(value, compact: true),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CategoryHistoryChart extends StatelessWidget {
  final List<({int year, int month, Map<String, double> totals})> months;
  final List<double> values;

  const _CategoryHistoryChart({required this.months, required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (values.length - 1).toDouble(),
            minY: 0,
            maxY: maxValue > 0 ? maxValue * 1.25 : 1,
            clipData: const FlClipData.all(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    if (value != value.roundToDouble()) {
                      return const SizedBox.shrink();
                    }
                    final index = value.toInt();
                    if (index < 0 || index >= months.length) {
                      return const SizedBox.shrink();
                    }
                    final month = months[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('MMM')
                            .format(DateTime(month.year, month.month)),
                        style: TextStyle(
                            fontSize: 9,
                            color: context.appColors.onSurfaceMuted),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => context.appColors.surfaceCard,
                getTooltipItems: (spots) => spots
                    .map((spot) => LineTooltipItem(
                          AppUtils.formatAmount(spot.y, compact: true),
                          const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: values
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                    .toList(),
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primary.withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryMonthRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isHighest;
  final bool isLowest;

  const _CategoryMonthRow({
    required this.label,
    required this.amount,
    required this.isHighest,
    required this.isLowest,
  });

  @override
  Widget build(BuildContext context) {
    final marker = isHighest
        ? 'Highest'
        : isLowest
            ? 'Lowest'
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurface)),
          ),
          if (marker != null) ...[
            Text(marker,
                style: TextStyle(
                    fontSize: 10,
                    color: isHighest ? AppTheme.expense : AppTheme.income,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
          ],
          Text(AppUtils.formatAmount(amount, compact: true),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 4 — CATEGORY CALCULATOR
// ════════════════════════════════════════════════════════════════
class _CategoryCalculatorTab extends ConsumerStatefulWidget {
  const _CategoryCalculatorTab();

  @override
  ConsumerState<_CategoryCalculatorTab> createState() =>
      _CategoryCalculatorTabState();
}

class _CategoryCalculatorTabState
    extends ConsumerState<_CategoryCalculatorTab> {
  final _selected = <String>{};
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final sm = ref.watch(selectedMonthProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Text('Expense calculator',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
            'Select categories and a date range to create a custom expense total.',
            style: TextStyle(
                fontSize: 12, color: context.appColors.onSurfaceMuted)),
        const SizedBox(height: 16),
        FutureBuilder<List<Transaction>>(
          future: IsarService.instance.getTransactionsByDateRange(_from, _to),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerList();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final transactions = snapshot.data ?? const <Transaction>[];
            final totals = <String, double>{};
            for (final transaction in transactions.where((t) => t.isExpense)) {
              totals[transaction.categoryName] =
                  (totals[transaction.categoryName] ?? 0) + transaction.amount;
            }
            final selectedTotal = _selected.fold<double>(
                0, (sum, name) => sum + (totals[name] ?? 0));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalculatorTotalCard(
                    total: selectedTotal, count: _selected.length),
                const SizedBox(height: 16),
                _CalculatorDateRange(
                  from: _from,
                  to: _to,
                  onChanged: (from, to) => setState(() {
                    _from = from;
                    _to = to;
                  }),
                  onReset: () {
                    setState(() {
                      _from = DateTime(sm.year, sm.month, 1);
                      _to = DateTime(sm.year, sm.month + 1, 1)
                          .subtract(const Duration(milliseconds: 1));
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text('SELECT CATEGORIES',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.onSurfaceMuted,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  data: (categories) {
                    final expenseCategories = categories
                        .where((category) =>
                            category.isExpense && category.enabled)
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expenseCategories.map((category) {
                        final isSelected = _selected.contains(category.name);
                        return FilterChip(
                          avatar: CategoryBadge(
                              icon: category.icon,
                              colorValue: category.colorValue,
                              size: 26),
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _selected.add(category.name);
                            } else {
                              _selected.remove(category.name);
                            }
                          }),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => Text('Error: $error'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CalculatorDateRange extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;
  final VoidCallback onReset;

  const _CalculatorDateRange({
    required this.from,
    required this.to,
    required this.onChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DATE RANGE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.onSurfaceMuted,
                    letterSpacing: 0.8)),
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: const Text('Selected month'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _dateButton(context, 'From', from, (date) {
                final start = DateTime(date.year, date.month, date.day);
                final end = to.isBefore(start)
                    ? DateTime(
                        start.year, start.month, start.day, 23, 59, 59, 999)
                    : to;
                onChanged(start, end);
              }),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 16),
            ),
            Expanded(
              child: _dateButton(context, 'To', to, (date) {
                final end =
                    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
                final start = from.isAfter(end)
                    ? DateTime(date.year, date.month, date.day)
                    : from;
                onChanged(start, end);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateButton(BuildContext context, String label, DateTime date,
      ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date.isAfter(DateTime.now()) ? DateTime.now() : date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: context.appColors.onSurfaceMuted)),
            const SizedBox(height: 3),
            Text(DateFormat('d MMM yyyy').format(date),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CalculatorTotalCard extends StatelessWidget {
  final double total;
  final int count;

  const _CalculatorTotalCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count == 0 ? 'Select categories' : 'Selected categories total',
              style: TextStyle(
                  fontSize: 12, color: context.appColors.onSurfaceMuted)),
          const SizedBox(height: 5),
          Text(AppUtils.formatAmount(total, compact: true),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 5 — INSIGHTS (weekday analysis + all-time stats + spending limit)
// ════════════════════════════════════════════════════════════════
class _InsightsTab extends ConsumerWidget {
  const _InsightsTab();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekdayAsync = ref.watch(weekdayTotalsProvider);
    final statsAsync = ref.watch(allTimeStatsProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final trendAsync = ref.watch(monthlyTrendProvider);
    final transactionsAsync = ref.watch(monthlyTransactionsProvider);
    final dailyAsync = ref.watch(dailyTotalsProvider);
    final categoryTotalsAsync = ref.watch(expenseCategoryTotalsProvider);
    final budgetsAsync = ref.watch(monthlyBudgetsProvider);
    final recurringAsync = ref.watch(recurringProvider);
    final savingsGoalsAsync = ref.watch(savingsGoalsProvider);
    final netWorthHistory = ref.watch(netWorthHistoryProvider);
    final accounts = ref.watch(accountsProvider);
    final totalBalance =
        accounts.fold<double>(0.0, (sum, a) => sum + a.balance);
    final limit = ref.watch(spendingLimitProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        summaryAsync.when(
          data: (summary) => trendAsync.when(
            data: (trend) => _buildMetricGrid(
                context, summary, trend, ref.watch(selectedMonthProvider)),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        transactionsAsync.when(
          data: (transactions) => summaryAsync.when(
            data: (summary) => trendAsync.when(
              data: (trend) => _buildHealthCard(
                context,
                transactions,
                summary.income,
                limit,
                ref.watch(selectedMonthProvider),
                trend,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        _buildDetailedInsights(
          context,
          transactionsAsync.valueOrNull,
          categoryTotalsAsync.valueOrNull,
          dailyAsync.valueOrNull,
          budgetsAsync.valueOrNull,
          recurringAsync.valueOrNull,
          totalBalance,
          statsAsync.valueOrNull?.avgMonthlySpend,
        ),
        _buildNetWorthChart(context, netWorthHistory),
        _buildBudgetProgress(
            context, budgetsAsync.valueOrNull, categoryTotalsAsync.valueOrNull),
        _buildSavingsGoalsOverview(context, savingsGoalsAsync.valueOrNull),
        // Spending limit alert card (if set)
        summaryAsync.when(
          data: (s) => limit != null
              ? _buildLimitCard(context, s.expense, limit)
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Weekday bar chart
        weekdayAsync.when(
          data: (wd) => _buildWeekdayChart(context, wd),
          loading: () => Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        // All-time stats
        statsAsync.when(
          data: (stats) => _buildAllTimeStats(context, stats),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMetricGrid(
    BuildContext context,
    ({double income, double expense, int count}) summary,
    List<({int year, int month, double expense, double income})> trend,
    SelectedMonth selectedMonth,
  ) {
    final net = summary.income - summary.expense;
    final savingsRate = summary.income > 0 ? net / summary.income : 0.0;
    final days = selectedMonth.isCurrentMonth
        ? DateTime.now().day
        : DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyAverage = days > 0 ? summary.expense / days : 0.0;
    final previousExpense =
        trend.length > 1 ? trend[trend.length - 2].expense : null;
    final change = previousExpense == null || previousExpense == 0
        ? null
        : (summary.expense - previousExpense) / previousExpense * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Net cash flow',
                    value: AppUtils.formatAmount(net, compact: true),
                    detail: net >= 0
                        ? 'Positive this month'
                        : 'Spending exceeds income',
                    color: net >= 0 ? AppTheme.income : AppTheme.expense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Savings rate',
                    value: '${(savingsRate * 100).toStringAsFixed(0)}%',
                    detail: summary.income > 0
                        ? 'Income kept'
                        : 'Add income to measure',
                    color: savingsRate >= 0.2 ? AppTheme.income : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Daily expense pace',
                    value: AppUtils.formatAmount(dailyAverage, compact: true),
                    detail: '${summary.count} transactions',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Month change',
                    value: change == null
                        ? 'No baseline'
                        : '${change.abs().toStringAsFixed(0)}%',
                    detail: change == null
                        ? 'Need previous spending'
                        : change <= 0
                            ? 'Lower than last month'
                            : 'Higher than last month',
                    color: change == null
                        ? context.appColors.onSurfaceMuted
                        : change <= 0
                            ? AppTheme.income
                            : AppTheme.expense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    BuildContext context,
    List<Transaction> transactions,
    double income,
    double? spendingLimit,
    SelectedMonth selectedMonth,
    List<({int year, int month, double expense, double income})> trend,
  ) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    final historicalMonthlyExpenses = trend.length > 1
        ? trend.sublist(0, trend.length - 1).map((t) => t.expense).toList()
        : const <double>[];
    final health = FinancialHealthEngine.analyze(
      transactions: transactions,
      monthlyIncome: income,
      spendingLimit: spendingLimit ?? 0,
      month: DateTime(selectedMonth.year, selectedMonth.month),
      historicalMonthlyExpenses: historicalMonthlyExpenses,
    );
    final scoreColor = health.score >= 60
        ? AppTheme.income
        : health.score >= 40
            ? Colors.orange
            : AppTheme.expense;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Financial health',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                onPressed: () => _showHealthInfoDialog(context),
                icon: Icon(Icons.info_outline,
                    size: 18, color: context.appColors.onSurfaceMuted),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              Text('${health.score}/100',
                  style: TextStyle(
                      color: scoreColor, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text(health.status,
              style: TextStyle(
                  color: scoreColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(health.tip,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: context.appColors.onSurfaceMuted, fontSize: 12)),
          const SizedBox(height: 14),
          _healthRatio(context, 'Needs', health.needsRatio, AppTheme.primary),
          _healthRatio(context, 'Wants', health.wantsRatio, Colors.orange),
          _healthRatio(
              context, 'Savings', health.savingsRatio, AppTheme.income),
          const SizedBox(height: 10),
          Text(
            'Projected month-end spending: ${AppUtils.formatAmount(health.projectedMonthEndExpense, compact: true)}',
            style: TextStyle(
                color: context.appColors.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _healthRatio(
      BuildContext context, String label, double ratio, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label,
                style: TextStyle(
                    color: context.appColors.onSurfaceMuted, fontSize: 11)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                backgroundColor: context.appColors.surfaceCard2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('${(ratio * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: context.appColors.onSurfaceMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showHealthInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How financial health works'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SCORE BANDS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8)),
              const SizedBox(height: 6),
              _infoLine('80\u2013100', 'Excellent', AppTheme.income),
              _infoLine('60\u201379', 'Good', AppTheme.income),
              _infoLine('40\u201359', 'Fair', Colors.orange),
              _infoLine('0\u201339', 'Needs Attention', AppTheme.expense),
              const SizedBox(height: 16),
              Text('NEEDS (essential, fixed)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              const Text(
                  'Rent, groceries, electricity, water, gas/cooking, fuel, '
                  'cab/auto/commute, loan EMIs, credit card bills, medical & '
                  'medicines, insurance, mobile/internet, child care, '
                  'education, maintenance/repairs, domestic help.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              Text('SAVINGS (building wealth)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.income,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              const Text(
                  'SIP/mutual funds, stocks/trading, gold, PF/NPS/pension, '
                  'fixed/recurring deposits, emergency fund, and any '
                  'category or note containing "savings" or "investment".',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              Text('WANTS (discretionary)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              const Text(
                  'Everything else — dining out, shopping, entertainment, '
                  'travel, subscriptions, gifts, and similar non-essential '
                  'spending.',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _infoLine(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 56,
              child: Text(range,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color))),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailedInsights(
    BuildContext context,
    List<Transaction>? transactions,
    Map<String, double>? categoryTotals,
    Map<int, double>? dailyTotals,
    List<Budget>? budgets,
    List<RecurringTransaction>? recurring,
    double totalBalance,
    double? avgMonthlySpend,
  ) {
    if (transactions == null || transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final expenseTxns = transactions.where((t) => t.isExpense).toList();
    final avgTransaction = expenseTxns.isEmpty
        ? null
        : expenseTxns.fold<double>(0, (sum, t) => sum + t.amount) /
            expenseTxns.length;

    MapEntry<int, double>? highestDay;
    for (final entry in (dailyTotals ?? const {}).entries) {
      if (highestDay == null || entry.value > highestDay!.value) {
        highestDay = entry;
      }
    }

    MapEntry<String, double>? topCategory;
    final totalExpense =
        (categoryTotals ?? const {}).values.fold<double>(0, (a, b) => a + b);
    for (final entry in (categoryTotals ?? const {}).entries) {
      if (topCategory == null || entry.value > topCategory!.value) {
        topCategory = entry;
      }
    }

    double? budgetUtilization;
    if (budgets != null && budgets.isNotEmpty) {
      final totalLimit =
          budgets.fold<double>(0, (sum, b) => sum + b.limitAmount);
      if (totalLimit > 0) {
        final totalSpent = budgets.fold<double>(
            0, (sum, b) => sum + (categoryTotals?[b.categoryName] ?? 0));
        budgetUtilization = totalSpent / totalLimit;
      }
    }

    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));
    final upcoming = (recurring ?? const [])
        .where((r) =>
            r.isActive &&
            r.isExpense &&
            r.nextDueDate.isAfter(now.subtract(const Duration(days: 1))) &&
            r.nextDueDate.isBefore(weekAhead))
        .toList();
    final upcomingTotal = upcoming.fold<double>(0, (sum, r) => sum + r.amount);

    final subscriptions = (recurring ?? const []).where((r) {
      final name = r.categoryName.toLowerCase();
      return r.isActive &&
          (name.contains('subscription') ||
              name.contains('ott') ||
              name.contains('streaming'));
    }).toList();
    final subscriptionMonthly =
        subscriptions.fold<double>(0, (sum, r) => sum + _monthlyEquivalent(r));

    final dailyValues = (dailyTotals ?? const {}).values.toList();
    String consistencyLabel = 'Not enough data';
    if (dailyValues.length >= 3) {
      final mean =
          dailyValues.fold<double>(0, (a, b) => a + b) / dailyValues.length;
      if (mean > 0) {
        final variance = dailyValues.fold<double>(
                0, (sum, v) => sum + (v - mean) * (v - mean)) /
            dailyValues.length;
        final coefficientOfVariation = math.sqrt(variance) / mean;
        consistencyLabel = coefficientOfVariation < 0.4
            ? 'Consistent'
            : coefficientOfVariation < 0.8
                ? 'Some variation'
                : 'Irregular';
      }
    }

    final emergencyMonths = (avgMonthlySpend != null && avgMonthlySpend > 0)
        ? totalBalance / avgMonthlySpend
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailed insights',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _insightRow(
            context,
            Icons.receipt_long_outlined,
            'Average transaction size',
            avgTransaction == null
                ? 'No expenses yet'
                : AppUtils.formatAmount(avgTransaction, compact: true),
          ),
          _insightRow(
            context,
            Icons.calendar_today_outlined,
            'Highest spending day',
            highestDay == null
                ? 'No data yet'
                : 'Day ${highestDay.key} · ${AppUtils.formatAmount(highestDay.value, compact: true)}',
          ),
          _insightRow(
            context,
            Icons.category_outlined,
            'Highest spending category',
            topCategory == null
                ? 'No expenses yet'
                : '${topCategory.key} · ${totalExpense > 0 ? (topCategory.value / totalExpense * 100).toStringAsFixed(0) : '0'}%',
          ),
          _insightRow(
            context,
            Icons.pie_chart_outline,
            'Budget utilization',
            budgetUtilization == null
                ? 'No budgets set'
                : '${(budgetUtilization * 100).toStringAsFixed(0)}% of limit used',
            valueColor: budgetUtilization == null
                ? null
                : budgetUtilization >= 1.0
                    ? AppTheme.expense
                    : budgetUtilization >= 0.8
                        ? Colors.orange
                        : AppTheme.income,
          ),
          _insightRow(
            context,
            Icons.event_repeat_outlined,
            'Upcoming recurring (7 days)',
            upcoming.isEmpty
                ? 'Nothing due soon'
                : '${upcoming.length} due · ${AppUtils.formatAmount(upcomingTotal, compact: true)}',
          ),
          _insightRow(
            context,
            Icons.subscriptions_outlined,
            'Subscriptions (est.)',
            subscriptions.isEmpty
                ? 'None tracked'
                : '${AppUtils.formatAmount(subscriptionMonthly, compact: true)}/mo · ${AppUtils.formatAmount(subscriptionMonthly * 12, compact: true)}/yr',
          ),
          _insightRow(
            context,
            Icons.show_chart_rounded,
            'Spending consistency',
            consistencyLabel,
          ),
          _insightRow(
            context,
            Icons.health_and_safety_outlined,
            'Emergency fund coverage',
            emergencyMonths == null
                ? 'Add income history to measure'
                : '${emergencyMonths.toStringAsFixed(1)} months of expenses',
            valueColor: emergencyMonths == null
                ? null
                : emergencyMonths >= 3
                    ? AppTheme.income
                    : emergencyMonths >= 1
                        ? Colors.orange
                        : AppTheme.expense,
          ),
        ],
      ),
    );
  }

  double _monthlyEquivalent(RecurringTransaction r) {
    switch (r.frequency) {
      case RecurringFrequency.daily:
        return r.amount * 30;
      case RecurringFrequency.weekly:
        return r.amount * 4.345;
      case RecurringFrequency.monthly:
        return r.amount;
      case RecurringFrequency.yearly:
        return r.amount / 12;
    }
  }

  Widget _insightRow(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.appColors.onSurfaceMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? context.appColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthChart(
      BuildContext context, List<NetWorthPoint> history) {
    if (history.length < 2) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up_rounded,
                size: 18, color: context.appColors.onSurfaceMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Net worth trend builds up as you use Paisa on different days.',
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted),
              ),
            ),
          ],
        ),
      );
    }

    final maxValue =
        history.map((e) => e.balance).reduce((a, b) => a > b ? a : b);
    final minValue =
        history.map((e) => e.balance).reduce((a, b) => a < b ? a : b);
    final span = (maxValue - minValue).abs();
    final maxY =
        maxValue + (span > 0 ? span * 0.15 : (maxValue.abs() * 0.1 + 100));
    final minY = minValue - (span > 0 ? span * 0.15 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net worth trend',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurface)),
          const SizedBox(height: 4),
          Text(AppUtils.formatAmount(history.last.balance),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.onSurface)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (history.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (history.length / 4)
                          .ceilToDouble()
                          .clamp(1, double.infinity),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d/M').format(history[i].date),
                            style: TextStyle(
                                fontSize: 9,
                                color: context.appColors.onSurfaceMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => context.appColors.surfaceCard2,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              AppUtils.formatAmount(s.y, compact: true),
                              const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: history
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.balance))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(BuildContext context, List<Budget>? budgets,
      Map<String, double>? categoryTotals) {
    if (budgets == null || budgets.isEmpty) return const SizedBox.shrink();

    final sorted = [...budgets]..sort((a, b) =>
        ((categoryTotals?[b.categoryName] ?? 0) /
                (b.limitAmount > 0 ? b.limitAmount : 1))
            .compareTo((categoryTotals?[a.categoryName] ?? 0) /
                (a.limitAmount > 0 ? a.limitAmount : 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget progress',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...sorted.map((budget) {
            final spent = categoryTotals?[budget.categoryName] ?? 0;
            final pct = budget.limitAmount > 0
                ? (spent / budget.limitAmount).clamp(0.0, 1.5)
                : 0.0;
            final color = pct >= 1.0
                ? AppTheme.expense
                : pct >= 0.8
                    ? Colors.orange
                    : AppTheme.income;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(budget.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.appColors.onSurface)),
                      ),
                      Text(
                        '${AppUtils.formatAmount(spent, compact: true)} / ${AppUtils.formatAmount(budget.limitAmount, compact: true)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0).toDouble(),
                      minHeight: 6,
                      backgroundColor: context.appColors.surfaceCard2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsOverview(
      BuildContext context, List<SavingsGoal>? goals) {
    if (goals == null || goals.isEmpty) return const SizedBox.shrink();
    final active = goals.where((g) => !g.isCompleted).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Savings goals progress',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...active.take(5).map((goal) {
            final color = AppUtils.colorFromValue(goal.colorValue);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.appColors.onSurface)),
                      ),
                      Text(
                        '${(goal.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 6,
                      backgroundColor: context.appColors.surfaceCard2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLimitCard(BuildContext context, double expense, double limit) {
    final pct = (expense / limit).clamp(0.0, 1.0);
    final isOver = expense > limit;
    final isNear = pct >= 0.8;
    final color = isOver
        ? AppTheme.expense
        : isNear
            ? Colors.orange
            : AppTheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOver
                    ? Icons.warning_amber_rounded
                    : isNear
                        ? Icons.warning_outlined
                        : Icons.shield_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOver
                      ? 'Spending Limit Exceeded!'
                      : isNear
                          ? 'Approaching Spending Limit'
                          : 'Monthly Spending Limit',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: context.appColors.surfaceCard2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppUtils.formatAmount(expense, compact: true)} spent',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
              Text(
                'Limit: ${AppUtils.formatAmount(limit, compact: true)}',
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayChart(BuildContext context, Map<int, double> wd) {
    if (wd.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const EmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'No data',
          subtitle: 'Add expenses to see weekday patterns',
        ),
      );
    }

    final maxEntry = wd.entries.reduce((a, b) => a.value > b.value ? a : b);
    final maxVal = maxEntry.value;
    final busiestDay = _weekdays[maxEntry.key - 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending by Weekday',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Most: $busiestDay',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.3 : 1000,
                barGroups: List.generate(7, (i) {
                  final weekday = i + 1;
                  final val = wd[weekday] ?? 0;
                  final isBusiest = weekday == maxEntry.key;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: isBusiest
                            ? AppTheme.primary
                            : val > 0
                                ? AppTheme.primary.withOpacity(0.4)
                                : context.appColors.surfaceCard2,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= 7) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weekdays[i],
                            style: TextStyle(
                                fontSize: 10,
                                color: context.appColors.onSurfaceMuted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.appColors.surfaceCard2,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${_weekdays[group.x]}\n${AppUtils.formatAmount(rod.toY, compact: true)}',
                      TextStyle(
                          fontSize: 10, color: context.appColors.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(7, (i) {
            final weekday = i + 1;
            final val = wd[weekday] ?? 0;
            final pct = maxVal > 0 ? val / maxVal : 0.0;
            final isBusiest = weekday == maxEntry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      _weekdays[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isBusiest ? FontWeight.w700 : FontWeight.normal,
                        color: isBusiest
                            ? AppTheme.primary
                            : context.appColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: context.appColors.surfaceCard2,
                        valueColor: AlwaysStoppedAnimation<Color>(isBusiest
                            ? AppTheme.primary
                            : AppTheme.primary.withOpacity(0.4)),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    child: Text(
                      val > 0 ? AppUtils.formatAmount(val, compact: true) : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isBusiest ? FontWeight.w700 : FontWeight.normal,
                        color: isBusiest
                            ? AppTheme.primary
                            : context.appColors.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllTimeStats(
    BuildContext context,
    ({
      double totalSpent,
      double totalIncome,
      int totalTxns,
      double avgMonthlySpend
    }) stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All-Time Stats',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurface)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _statBox(
                      context,
                      'Total Spent',
                      AppUtils.formatAmount(stats.totalSpent, compact: true),
                      AppTheme.expense)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statBox(
                      context,
                      'Total Income',
                      AppUtils.formatAmount(stats.totalIncome, compact: true),
                      AppTheme.income)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _statBox(context, 'Transactions',
                      stats.totalTxns.toString(), AppTheme.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statBox(
                      context,
                      'Avg/Month',
                      AppUtils.formatAmount(stats.avgMonthlySpend,
                          compact: true),
                      Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: context.appColors.onSurfaceMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TAB 4 — TOP SPENDS
// ════════════════════════════════════════════════════════════════
class _TopSpendsTab extends ConsumerWidget {
  const _TopSpendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topExpensesProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return topAsync.when(
      data: (txns) {
        if (txns.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            subtitle: 'Your biggest expenses this month will appear here',
          );
        }

        final totalExpense =
            summaryAsync.whenOrNull(data: (s) => s.expense) ?? 0;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: txns.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Top ${txns.length} expenses this month',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurfaceMuted,
                      letterSpacing: 0.5),
                ),
              );
            }
            final t = txns[i - 1];
            final rank = i;
            final pct = totalExpense > 0 ? t.amount / totalExpense * 100 : 0.0;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? _rankColor(context, rank).withOpacity(0.15)
                          : context.appColors.surfaceCard2,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: rank <= 3
                                ? _rankColor(context, rank)
                                : context.appColors.onSurfaceMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CategoryBadge(
                      icon: t.categoryIcon,
                      colorValue: t.categoryColor,
                      size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.description.isEmpty
                              ? t.categoryName
                              : t.description,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(t.categoryName,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.appColors.onSurfaceMuted),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            Text('·',
                                style: TextStyle(
                                    color: context.appColors.onSurfaceMuted)),
                            const SizedBox(width: 6),
                            Text(AppUtils.formatDate(t.date),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.appColors.onSurfaceMuted)),
                          ],
                        ),
                        SizedBox(height: 5),
                        // % bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: context.appColors.surfaceCard2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.expense.withOpacity(0.6)),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatAmount(t.amount, compact: true),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.expense),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 10,
                            color: context.appColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const ShimmerList(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Color _rankColor(BuildContext context, int rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (rank) {
      case 1:
        return isDark
            ? const Color(0xFFFFD700)
            : const Color(0xFFB8860B); // gold
      case 2:
        return isDark
            ? const Color(0xFFB0B0B0)
            : const Color(0xFF757575); // silver
      case 3:
        return isDark
            ? const Color(0xFFCD7F32)
            : const Color(0xFF8B5A2B); // bronze
      default:
        return context.appColors.onSurfaceMuted;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// SHARED WIDGETS (local to this file)
// ════════════════════════════════════════════════════════════════
Color _analyticsChartColor(List<Color> palette, int index) {
  final base = palette[index % palette.length];
  final cycle = index ~/ palette.length;
  if (cycle == 0) return base;

  final hsl = HSLColor.fromColor(base);
  return hsl
      .withHue((hsl.hue + cycle * 19) % 360)
      .withLightness((hsl.lightness + (cycle.isEven ? 0.08 : -0.08))
          .clamp(0.25, 0.75)
          .toDouble())
      .toColor();
}

/// Picks black or white text for readability against a fill color of any
/// brightness (some chart palette colors are pale pastels).
Color _readableOnColor(Color background) {
  return background.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: context.appColors.onSurfaceMuted, fontSize: 10)),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: context.appColors.onSurfaceMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final List<MapEntry<String, double>> sorted;
  final double total;
  final List<Color> colors;
  final TransactionType type;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _PieChartCard({
    required this.sorted,
    required this.total,
    required this.colors,
    required this.type,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            AppUtils.formatAmount(total),
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: context.appColors.onSurface),
          ),
          Text(
            'Total ${type == TransactionType.expense ? 'Expenses' : 'Income'}',
            style: TextStyle(
                fontSize: 12, color: context.appColors.onSurfaceMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      onTouch(-1);
                      return;
                    }
                    onTouch(response.touchedSection!.touchedSectionIndex);
                  },
                ),
                sections: sorted.asMap().entries.map((e) {
                  final i = e.key;
                  final isTouched = i == touchedIndex;
                  final pct = total > 0 ? e.value.value / total * 100 : 0.0;
                  return PieChartSectionData(
                    value: e.value.value,
                    color: _analyticsChartColor(colors, i),
                    radius: isTouched ? 88 : 72,
                    title: isTouched
                        ? '${pct.toStringAsFixed(1)}%'
                        : pct > 7
                            ? '${pct.toStringAsFixed(0)}%'
                            : '',
                    titleStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            _readableOnColor(_analyticsChartColor(colors, i))),
                  );
                }).toList(),
                centerSpaceRadius: 46,
                sectionsSpace: 2,
              ),
            ),
          ),
          // Touch hint
          if (touchedIndex >= 0 && touchedIndex < sorted.length) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _analyticsChartColor(colors, touchedIndex),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  sorted[touchedIndex].key,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurface),
                ),
              ],
            ),
            Text(
              AppUtils.formatAmount(sorted[touchedIndex].value),
              style: TextStyle(
                  fontSize: 12, color: context.appColors.onSurfaceMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final double amount;
  final double percent;
  final Color color;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.onSurface),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                AppUtils.formatAmount(amount, compact: true),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.onSurface),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                child: Text('${percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11, color: context.appColors.onSurfaceMuted),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: context.appColors.surfaceCard2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
