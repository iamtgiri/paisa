import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../models/budget.dart';
import '../../models/isar_service.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../utils/financial_insights.dart';
import '../../widgets/shared_widgets.dart';
import '../transactions/add_transaction_sheet.dart';
import '../transactions/transaction_detail_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sm = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final recentAsync = ref.watch(monthlyTransactionsProvider);
    final categoryTotals = ref.watch(expenseCategoryTotalsProvider);
    final budgetsAsync = ref.watch(monthlyBudgetsProvider);
    final accounts = ref.watch(accountsProvider);
    final trendAsync = ref.watch(monthlyTrendProvider);
    final limit = ref.watch(spendingLimitProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            toolbarHeight: 60,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Paisa',
                      style: Theme.of(context).textTheme.displaySmall),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => ref
                            .read(selectedMonthProvider.notifier)
                            .state = sm.prev(),
                        child: const Icon(Icons.chevron_left,
                            color: AppTheme.onSurface),
                      ),
                      Text(
                        AppUtils.formatMonthYear(sm.year, sm.month),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      GestureDetector(
                        onTap: sm.isCurrentMonth
                            ? null
                            : () => ref
                                .read(selectedMonthProvider.notifier)
                                .state = sm.next(),
                        child: Icon(Icons.chevron_right,
                            color: sm.isCurrentMonth
                                ? AppTheme.onSurfaceMuted
                                : AppTheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Hero balance card ─────────────────────────────────
          SliverToBoxAdapter(
            child: summary.when(
              data: (s) => _HeroCard(
                income: s.income,
                expense: s.expense,
                count: s.count,
                spendingLimit: limit,
              ),
              loading: () => Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                height: 190,
                decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Accounts overview ────────────────────────────────
          SliverToBoxAdapter(
            child: _AccountOverview(accounts: accounts),
          ),

          // ── Month-over-month insight ──────────────────────────
          SliverToBoxAdapter(
            child: trendAsync.when(
              data: (trend) => _FinancialPulse(trend: trend),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Burn-rate insight ────────────────────────────────
          SliverToBoxAdapter(
            child: summary.when(
              data: (s) {
                final historicalExpenses = trendAsync.whenOrNull(
                  data: (trend) {
                    if (trend.length < 2) return null;
                    return trend
                        .take(trend.length - 1)
                        .where((item) => item.expense > 0)
                        .map((item) => item.expense)
                        .toList();
                  },
                );
                return _BurnRateCard(
                  insight: FinancialInsights.calculateBurnRate(
                    expense: s.expense,
                    month: DateTime(sm.year, sm.month),
                    now: DateTime.now(),
                    spendingLimit: limit,
                    historicalMonthlyExpenses: historicalExpenses,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Top category strip ────────────────────────────────
          SliverToBoxAdapter(
            child: categoryTotals.when(
              data: (totals) => _buildTopCategory(context, totals),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Budget overview strip ─────────────────────────────
          SliverToBoxAdapter(
            child: budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) return const SizedBox.shrink();
                return categoryTotals.when(
                  data: (totals) =>
                      _buildBudgetStrip(context, ref, budgets, totals),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // ── Quick-add favorites ───────────────────────────────
          SliverToBoxAdapter(child: _buildFavoritesSection(context, ref)),

          // ── Recent header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RECENT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceMuted,
                          letterSpacing: 0.8)),
                  recentAsync.whenOrNull(
                        data: (txns) => Text(
                          '${txns.length} transactions',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.onSurfaceMuted),
                        ),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // ── Recent transactions ───────────────────────────────
          recentAsync.when(
            data: (txns) {
              final recent = txns.take(10).toList();
              if (recent.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      subtitle: 'Tap + to add your first transaction',
                      action: ElevatedButton.icon(
                        onPressed: () => _addTransaction(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Transaction'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(180, 44)),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: EdgeInsets.fromLTRB(16, i == 0 ? 10 : 4, 16, 4),
                    child: TransactionTile(
                      transaction: recent[i],
                      onTap: () => _showDetail(context, recent[i]),
                    ),
                  ),
                  childCount: recent.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: ShimmerList()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dash_fab',
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopCategory(BuildContext context, Map<String, double> totals) {
    if (totals.isEmpty) return const SizedBox.shrink();
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sorted.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.bar_chart,
                size: 13, color: AppTheme.onSurfaceMuted),
            const SizedBox(width: 7),
            const Text('Top spend: ',
                style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted)),
            Flexible(
              child: Text(topCat.key,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(
              AppUtils.formatAmount(topCat.value, compact: true),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.expense),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStrip(
    BuildContext context,
    WidgetRef ref,
    List<Budget> budgets,
    Map<String, double> totals,
  ) {
    // Only show budgets that are at ≥70% or over limit
    final alertBudgets = budgets.where((b) {
      final spent = totals[b.categoryName] ?? 0.0;
      return b.limitAmount > 0 && spent / b.limitAmount >= 0.7;
    }).toList();

    if (alertBudgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text('BUDGET ALERTS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceMuted,
                  letterSpacing: 0.8)),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: alertBudgets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final b = alertBudgets[i];
              final spent = totals[b.categoryName] ?? 0.0;
              final pct = (spent / b.limitAmount).clamp(0.0, 1.0);
              final isOver = spent > b.limitAmount;
              final color = AppUtils.colorFromValue(b.categoryColor);
              final barColor = isOver ? AppTheme.expense : Colors.orange;

              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: barColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CategoryBadge(
                            icon: b.categoryIcon,
                            colorValue: b.categoryColor,
                            size: 24),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(b.categoryName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isOver)
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppTheme.expense),
                      ],
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppTheme.surfaceCard2,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${AppUtils.formatAmount(spent, compact: true)} / ${AppUtils.formatAmount(b.limitAmount, compact: true)}',
                      style: TextStyle(
                          fontSize: 10,
                          color: barColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoriteTransactionsProvider);
    return favsAsync.when(
      data: (favs) {
        if (favs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('QUICK ADD',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceMuted,
                      letterSpacing: 0.8)),
            ),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => _FavoriteQuickCard(
                  transaction: favs[i],
                  onTap: () => _quickAdd(context, ref, favs[i]),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _quickAdd(
      BuildContext context, WidgetRef ref, Transaction fav) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(fav.description.isEmpty ? fav.categoryName : fav.description),
        content: Text('Add ${AppUtils.formatAmount(fav.amount)} today?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final newTxn = Transaction.create(
        amount: fav.amount,
        categoryId: fav.categoryId,
        categoryName: fav.categoryName,
        categoryColor: fav.categoryColor,
        categoryIcon: fav.categoryIcon,
        date: DateTime.now(),
        description: fav.description,
        paymentAccountId: fav.paymentAccountId,
        paymentMethod: fav.paymentMethod,
        type: fav.type,
        tags: List.from(fav.tags),
        isFavorite: false,
      );
      await IsarService.instance.saveTransaction(newTxn);
      await ref.read(accountsProvider.notifier).applyTransaction(newTxn);
      ref.read(transactionsRefreshProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added!')),
        );
      }
    }
  }

  void _showDetail(BuildContext context, Transaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(transaction: t),
    );
  }

  Future<void> _addTransaction(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

class _AccountOverview extends StatelessWidget {
  final List<Account> accounts;

  const _AccountOverview({required this.accounts});

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final total =
        accounts.fold<double>(0, (sum, account) => sum + account.balance);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR MONEY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  AppUtils.formatAmount(total, compact: true),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _AccountBalanceCard(
                account: accounts[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBalanceCard extends StatelessWidget {
  final Account account;

  const _AccountBalanceCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final color = AppUtils.colorFromValue(account.colorValue);

    return Container(
      width: 164,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppUtils.iconFromHex(account.icon),
                size: 17, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppUtils.formatAmount(account.balance, compact: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialPulse extends StatelessWidget {
  final List<({int year, int month, double expense, double income})> trend;

  const _FinancialPulse({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.length < 2) return const SizedBox.shrink();

    final current = trend.last;
    final previous = trend[trend.length - 2];
    if (current.expense == 0 &&
        current.income == 0 &&
        previous.expense == 0 &&
        previous.income == 0) {
      return const SizedBox.shrink();
    }

    final expenseChange = _percentageChange(previous.expense, current.expense);
    final currentSavings = current.income - current.expense;
    final previousSavings = previous.income - previous.expense;
    final savingsImproved = currentSavings >= previousSavings;
    final accent = savingsImproved ? AppTheme.income : Colors.orange;
    final changeText = previous.expense == 0
        ? 'No previous spending baseline'
        : '${expenseChange.abs().toStringAsFixed(0)}% ${expenseChange >= 0 ? 'more' : 'less'} spending';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                savingsImproved
                    ? Icons.trending_up_rounded
                    : Icons.insights_outlined,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savingsImproved
                        ? 'Your money is moving well'
                        : 'A closer look may help',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$changeText compared with last month',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              AppUtils.formatAmount(currentSavings, compact: true),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _percentageChange(double previous, double current) {
    if (previous == 0) return current == 0 ? 0 : 100;
    return ((current - previous) / previous) * 100;
  }
}

class _BurnRateCard extends StatelessWidget {
  final BurnRateInsight insight;

  const _BurnRateCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    if (insight.dailyRate <= 0) return const SizedBox.shrink();

    final accent = insight.isOverLimit ? AppTheme.expense : AppTheme.primary;
    final projection = AppUtils.formatAmount(
      insight.projectedExpense,
      compact: true,
    );
    final limitMessage = insight.limitDifference == null
        ? 'No monthly limit is set.'
        : insight.isOverLimit
            ? '${AppUtils.formatAmount(insight.limitDifference!, compact: true)} over your limit.'
            : '${AppUtils.formatAmount(insight.limitDifference!.abs(), compact: true)} below your limit.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              insight.isOverLimit
                  ? Icons.speed_outlined
                  : Icons.insights_outlined,
              size: 22,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projected month-end spend: $projection',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${AppUtils.formatAmount(insight.dailyRate, compact: true)}/day. $limitMessage',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO CARD — animated balance counter
// ═══════════════════════════════════════════════════════════════
class _HeroCard extends StatefulWidget {
  final double income;
  final double expense;
  final int count;
  final double? spendingLimit;

  const _HeroCard({
    required this.income,
    required this.expense,
    required this.count,
    this.spendingLimit,
  });

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_HeroCard old) {
    super.didUpdateWidget(old);
    if (old.income != widget.income || old.expense != widget.expense) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.income - widget.expense;
    final savings = widget.income > 0
        ? ((balance / widget.income) * 100).clamp(-999.0, 100.0)
        : 0.0;

    // Spending limit progress
    final limitPct = widget.spendingLimit != null && widget.spendingLimit! > 0
        ? (widget.expense / widget.spendingLimit!).clamp(0.0, 1.0)
        : null;
    final limitOver =
        widget.spendingLimit != null && widget.expense > widget.spendingLimit!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        border: Border.all(
          color: limitOver
              ? AppTheme.expense.withOpacity(0.3)
              : AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          // Animated balance counter
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final displayed = balance * _anim.value;
              return Text(
                AppUtils.formatAmount(displayed),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: balance >= 0 ? AppTheme.onSurface : AppTheme.expense,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          if (widget.income > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _heroStat(
                  'Saved',
                  '${savings.toStringAsFixed(0)}%',
                  savings >= 30
                      ? AppTheme.income
                      : savings >= 10
                          ? Colors.orange
                          : AppTheme.expense,
                ),
                const SizedBox(width: 24),
                _heroStat(
                    'Transactions', widget.count.toString(), AppTheme.primary),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: SummaryCard(
                label: 'Income',
                amount: widget.income,
                color: AppTheme.income,
                icon: Icons.arrow_downward_rounded,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: SummaryCard(
                label: 'Expense',
                amount: widget.expense,
                color: AppTheme.expense,
                icon: Icons.arrow_upward_rounded,
              )),
            ],
          ),
          // Spending limit bar
          if (limitPct != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  limitOver ? '⚠ Over limit!' : 'Monthly limit',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        limitOver ? AppTheme.expense : AppTheme.onSurfaceMuted,
                    fontWeight: limitOver ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                Text(
                  '${(limitPct * 100).toStringAsFixed(0)}% of ${AppUtils.formatAmount(widget.spendingLimit!, compact: true)}',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        limitOver ? AppTheme.expense : AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: limitPct,
                backgroundColor: AppTheme.surfaceCard2,
                valueColor: AlwaysStoppedAnimation<Color>(limitOver
                    ? AppTheme.expense
                    : limitPct >= 0.8
                        ? Colors.orange
                        : AppTheme.primary),
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.onSurfaceMuted)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK-ADD FAVORITE CARD
// ═══════════════════════════════════════════════════════════════
class _FavoriteQuickCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _FavoriteQuickCard({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryBadge(
                icon: t.categoryIcon, colorValue: t.categoryColor, size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t.description.isEmpty ? t.categoryName : t.description,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppUtils.formatAmount(t.amount, compact: true),
                  style: TextStyle(
                    fontSize: 11,
                    color: t.isExpense ? AppTheme.expense : AppTheme.income,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
