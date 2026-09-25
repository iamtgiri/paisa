import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/isar_service.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';
import 'add_transaction_sheet.dart';
import 'transaction_detail_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sm = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: context.appColors.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => ref
                        .read(selectedMonthProvider.notifier)
                        .state = sm.prev(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32),
                  ),
                  Text(
                    AppUtils.formatMonthYear(sm.year, sm.month),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: sm.isCurrentMonth
                            ? context.appColors.onSurfaceMuted
                            : null),
                    onPressed: sm.isCurrentMonth
                        ? null
                        : () => ref.read(selectedMonthProvider.notifier).state =
                            sm.next(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: filter.hasActiveFilter,
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body:
          _showSearch ? _buildSearchResults() : _buildTransactionsList(summary),
      floatingActionButton: FloatingActionButton(
        heroTag: 'txn_fab',
        onPressed: () => _addTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionsList(
      AsyncValue<({double income, double expense, int count})> summary) {
    final txnsAsync = ref.watch(filteredTransactionsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: summary.when(
            data: (s) => _buildSummaryStrip(s.income, s.expense),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        txnsAsync.when(
          data: (txns) {
            if (txns.isEmpty) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions',
                  subtitle: 'Tap + to add your first transaction',
                ),
              );
            }
            final grouped = _groupByDate(txns);
            final keys = grouped.keys.toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final dateKey = keys[i];
                  final items = grouped[dateKey]!;
                  final dayTotal = items.fold<double>(0,
                      (sum, t) => sum + (t.isExpense ? -t.amount : t.amount));
                  return _buildDateGroup(dateKey, items, dayTotal);
                },
                childCount: keys.length,
              ),
            );
          },
          loading: () => const SliverFillRemaining(child: ShimmerList()),
          error: (e, _) =>
              SliverFillRemaining(child: Center(child: Text('Error: $e'))),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
      ],
    );
  }

  Widget _buildSummaryStrip(double income, double expense) {
    final balance = income - expense;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
              child: _stripItem('Income', income, AppTheme.income,
                  Icons.arrow_downward_rounded)),
          Container(width: 1, height: 32, color: context.appColors.divider),
          Expanded(
              child: _stripItem('Expense', expense, AppTheme.expense,
                  Icons.arrow_upward_rounded)),
          Container(width: 1, height: 32, color: context.appColors.divider),
          Expanded(
              child: _stripItem(
                  'Balance',
                  balance,
                  balance >= 0 ? AppTheme.income : AppTheme.expense,
                  Icons.account_balance_wallet_outlined)),
        ],
      ),
    );
  }

  Widget _stripItem(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(height: 3),
        Text(
          AppUtils.formatAmount(amount, compact: true),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.appColors.onSurfaceMuted)),
      ],
    );
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txns) {
    final map = <String, List<Transaction>>{};
    for (final t in txns) {
      final key = AppUtils.formatDate(t.date);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  Widget _buildDateGroup(
      String dateLabel, List<Transaction> txns, double dayTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurfaceMuted,
                      letterSpacing: 0.5),
                ),
                Text(
                  (dayTotal >= 0 ? '+' : '') +
                      AppUtils.formatAmount(dayTotal.abs(), compact: true),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          dayTotal >= 0 ? AppTheme.income : AppTheme.expense),
                ),
              ],
            ),
          ),
          ...txns.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < txns.length - 1 ? 6 : 0),
              child: TransactionTile(
                transaction: t,
                onTap: () => _showDetail(context, t),
                onDelete: () => _deleteTransaction(t),
                onEdit: () => _editTransaction(context, t),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = ref.watch(searchResultsProvider);
    return results.when(
      data: (txns) {
        if (_searchCtrl.text.isEmpty) {
          return const EmptyState(
            icon: Icons.search,
            title: 'Search transactions',
            subtitle: 'Search by amount, category, description or tags',
          );
        }
        if (txns.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'No results',
            subtitle: 'No transactions match "${_searchCtrl.text}"',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: txns.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => TransactionTile(
            transaction: txns[i],
            onTap: () => _showDetail(context, txns[i]),
            onDelete: () => _deleteTransaction(txns[i]),
            onEdit: () => _editTransaction(context, txns[i]),
          ),
        );
      },
      loading: () => const ShimmerList(),
      error: (_, __) => const SizedBox.shrink(),
    );
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

  Future<void> _editTransaction(BuildContext context, Transaction t) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(existing: t),
    );
  }

  Future<void> _deleteTransaction(Transaction t) async {
    await ref.read(accountsProvider.notifier).reverseTransaction(t);
    await IsarService.instance.deleteTransaction(t.id);
    ref.read(transactionsRefreshProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Re-insert the same transaction (new id will be auto-assigned by Isar)
              final restored = Transaction.create(
                amount: t.amount,
                categoryId: t.categoryId,
                categoryName: t.categoryName,
                categoryColor: t.categoryColor,
                categoryIcon: t.categoryIcon,
                date: t.date,
                description: t.description,
                paymentAccountId: t.paymentAccountId,
                paymentMethod: t.paymentMethod,
                type: t.type,
                tags: List.from(t.tags),
                isFavorite: t.isFavorite,
              );
              await IsarService.instance.saveTransaction(restored);
              await ref
                  .read(accountsProvider.notifier)
                  .applyTransaction(restored);
              ref.read(transactionsRefreshProvider.notifier).refresh();
            },
          ),
        ),
      );
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final accounts = ref.watch(accountsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: context.appColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter & Sort',
                  style: Theme.of(context).textTheme.titleLarge),
              if (filter.hasActiveFilter)
                TextButton(
                  onPressed: () {
                    ref.read(transactionFilterProvider.notifier).state =
                        const TransactionFilter();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('TYPE',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(context, 'All', filter.type == null, () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(clearType: true);
              }),
              _filterChip(
                  context, 'Expenses', filter.type == TransactionType.expense,
                  () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: TransactionType.expense);
              }),
              _filterChip(
                  context, 'Income', filter.type == TransactionType.income, () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(type: TransactionType.income);
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text('ACCOUNTS',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            Text('No accounts available',
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accounts.map((account) {
                final selected = filter.accountIds.contains(account.id);
                return FilterChip(
                  avatar: Icon(AppUtils.iconFromHex(account.icon),
                      size: 16,
                      color: AppUtils.colorFromValue(account.colorValue)),
                  label: Text(account.name),
                  selected: selected,
                  onSelected: (value) {
                    final selectedAccounts = {...filter.accountIds};
                    if (value) {
                      selectedAccounts.add(account.id);
                    } else {
                      selectedAccounts.remove(account.id);
                    }
                    ref.read(transactionFilterProvider.notifier).state =
                        filter.copyWith(accountIds: selectedAccounts);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          Text('SORT BY',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(context, 'Latest First',
                  filter.sortBy == 'date' && filter.sortDesc, () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(sortBy: 'date', sortDesc: true);
              }),
              _filterChip(context, 'Oldest First',
                  filter.sortBy == 'date' && !filter.sortDesc, () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(sortBy: 'date', sortDesc: false);
              }),
              _filterChip(context, 'Highest First',
                  filter.sortBy == 'amount' && filter.sortDesc, () {
                ref.read(transactionFilterProvider.notifier).state =
                    filter.copyWith(sortBy: 'amount', sortDesc: true);
              }),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.15)
              : context.appColors.surfaceCard2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            color:
                selected ? AppTheme.primary : context.appColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
