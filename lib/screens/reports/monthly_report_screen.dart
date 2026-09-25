import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/budget.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../utils/financial_insights.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sm = ref.watch(selectedMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final expTotals = ref.watch(expenseCategoryTotalsProvider);
    final incTotals = ref.watch(incomeCategoryTotalsProvider);
    final topAsync = ref.watch(topExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Report — ${AppUtils.formatMonthYear(sm.year, sm.month)}'),
        actions: [
          summaryAsync.whenOrNull(
                data: (_) => IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copyReport(context, ref, sm),
                  tooltip: 'Copy report',
                ),
              ) ??
              const SizedBox.shrink(),
          summaryAsync.whenOrNull(
                data: (_) => IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareReport(context, ref, sm),
                  tooltip: 'Share report',
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(context, summary, sm),
            const SizedBox(height: 16),
            expTotals.when(
              data: (totals) => _buildCategorySection(
                  context, 'Expenses', totals, AppTheme.expense),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            incTotals.when(
              data: (totals) => _buildCategorySection(
                  context, 'Income', totals, AppTheme.income),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            topAsync.when(
              data: (txns) => _buildTopExpenses(context, txns),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 80),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ({double income, double expense, int count}) summary,
    SelectedMonth sm,
  ) {
    final balance = summary.income - summary.expense;
    final savings = summary.income > 0
        ? ((balance / summary.income) * 100).clamp(-999.0, 100.0)
        : 0.0;
    final savingsColor = savings >= 30
        ? AppTheme.income
        : savings >= 10
            ? Colors.orange
            : AppTheme.expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.18),
            AppTheme.primaryDark.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppUtils.formatMonthYear(sm.year, sm.month),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 8),
          Text('Monthly Report',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          // Big three stats
          Row(
            children: [
              Expanded(
                child: _reportStat(
                    'Income',
                    AppUtils.formatAmount(summary.income, compact: true),
                    AppTheme.income),
              ),
              Expanded(
                child: _reportStat(
                    'Expense',
                    AppUtils.formatAmount(summary.expense, compact: true),
                    AppTheme.expense),
              ),
              Expanded(
                child: _reportStat(
                    'Balance',
                    AppUtils.formatAmount(balance, compact: true),
                    balance >= 0 ? AppTheme.income : AppTheme.expense),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _reportStat('Savings Rate',
                    '${savings.toStringAsFixed(1)}%', savingsColor),
              ),
              Expanded(
                child: _reportStat(
                    'Transactions', summary.count.toString(), AppTheme.primary),
              ),
              Expanded(
                child: _reportStat(
                    'Daily Avg',
                    AppUtils.formatAmount(
                        summary.expense /
                            DateTime(sm.year, sm.month + 1, 0).day,
                        compact: true),
                    AppTheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.onSurfaceMuted)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    Map<String, double> totals,
    Color accentColor,
  ) {
    if (totals.isEmpty) return const SizedBox.shrink();
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface)),
              Text(AppUtils.formatAmount(total, compact: true),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted.take(5).map((e) {
            final pct = total > 0 ? e.value / total * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(e.key,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.onSurface),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: AppTheme.surfaceCard2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor.withOpacity(0.7)),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      AppUtils.formatAmount(e.value, compact: true),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (sorted.length > 5) ...[
            const SizedBox(height: 6),
            Text(
              '+${sorted.length - 5} more categories',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopExpenses(BuildContext context, List<Transaction> txns) {
    if (txns.isEmpty) return const SizedBox.shrink();
    final top = txns.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Largest Expenses',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) {
            final t = e.value;
            final medals = ['🥇', '🥈', '🥉'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(medals[e.key], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.description.isEmpty
                              ? t.categoryName
                              : t.description,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${t.categoryName} · ${AppUtils.formatDate(t.date)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppUtils.formatAmount(t.amount, compact: true),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.expense),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _shareReport(
    BuildContext context,
    WidgetRef ref,
    SelectedMonth sm,
  ) async {
    final summary = await ref.read(monthlySummaryProvider.future);
    final expTotals = await ref.read(expenseCategoryTotalsProvider.future);
    final topExpenses = await ref.read(topExpensesProvider.future);
    final budgets = await ref.read(monthlyBudgetsProvider.future);
    final text = _buildReportText(
      sm: sm,
      summary: summary,
      expenseTotals: expTotals,
      topExpenses: topExpenses,
      budgets: budgets,
    );
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/paisa_report_${sm.year}_${sm.month.toString().padLeft(2, '0')}.txt');
    await file.writeAsString(text);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      text: text,
      subject:
          'Paisa Monthly Report — ${AppUtils.formatMonthYear(sm.year, sm.month)}',
    );
  }

  Future<void> _copyReport(
      BuildContext context, WidgetRef ref, SelectedMonth sm) async {
    final summary = await ref.read(monthlySummaryProvider.future);
    final expTotals = await ref.read(expenseCategoryTotalsProvider.future);
    final topExpenses = await ref.read(topExpensesProvider.future);
    final budgets = await ref.read(monthlyBudgetsProvider.future);
    final text = _buildReportText(
      sm: sm,
      summary: summary,
      expenseTotals: expTotals,
      topExpenses: topExpenses,
      budgets: budgets,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monthly report copied')),
      );
    }
  }

  String _buildReportText({
    required SelectedMonth sm,
    required ({double income, double expense, int count}) summary,
    required Map<String, double> expenseTotals,
    required List<Transaction> topExpenses,
    required List<Budget> budgets,
  }) {
    final balance = summary.income - summary.expense;
    final savings = summary.income > 0
        ? ((balance / summary.income) * 100).clamp(-999.0, 100.0)
        : 0.0;
    final insight = FinancialInsights.calculateBurnRate(
      expense: summary.expense,
      month: DateTime(sm.year, sm.month),
      now: DateTime.now(),
      spendingLimit: budgets.isEmpty
          ? null
          : budgets.fold<double>(0, (sum, budget) => sum + budget.limitAmount),
    );

    final categoryLines = (expenseTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .map((e) => '- ${e.key}: ${AppUtils.formatAmount(e.value)}')
        .join('\n');
    final expenseLines = topExpenses.take(5).map((t) {
      final label = t.description.isEmpty ? t.categoryName : t.description;
      return '- $label: ${AppUtils.formatAmount(t.amount)}';
    }).join('\n');
    final budgetText = budgets.isEmpty
        ? 'No category budgets set'
        : '${budgets.length} category budget(s), ${AppUtils.formatAmount(budgets.fold<double>(0, (sum, b) => sum + b.limitAmount))} total limit';

    return '''Paisa Monthly Report
${AppUtils.formatMonthYear(sm.year, sm.month)}
================================
Income:       ${AppUtils.formatAmount(summary.income)}
Expense:      ${AppUtils.formatAmount(summary.expense)}
Balance:      ${AppUtils.formatAmount(balance)}
Savings rate: ${savings.toStringAsFixed(1)}%
Transactions: ${summary.count}
Daily pace:   ${AppUtils.formatAmount(insight.dailyRate)}/day
Projection:   ${AppUtils.formatAmount(insight.projectedExpense)} by month end
Budgets:      $budgetText

Spending by category
$categoryLines

Largest expenses
${expenseLines.isEmpty ? '- None' : expenseLines}

Generated locally by Paisa''';
  }
}
