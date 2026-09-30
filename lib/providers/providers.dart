import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';

import '../models/account.dart';
import '../models/app_prefs.dart';
import '../models/isar_service.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring.dart';
import '../models/pending_transaction.dart';
import '../services/notification_capture_service.dart';
import '../utils/transaction_sms_parser.dart';

// ─── Selected Month ────────────────────────────────────────────
class SelectedMonth {
  final int year;
  final int month;
  const SelectedMonth(this.year, this.month);

  SelectedMonth prev() {
    if (month == 1) return SelectedMonth(year - 1, 12);
    return SelectedMonth(year, month - 1);
  }

  SelectedMonth next() {
    final now = DateTime.now();
    if (year == now.year && month == now.month) return this;
    if (month == 12) return SelectedMonth(year + 1, 1);
    return SelectedMonth(year, month + 1);
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
}

final selectedMonthProvider = StateProvider<SelectedMonth>((ref) {
  final now = DateTime.now();
  return SelectedMonth(now.year, now.month);
});

// ─── Categories ────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return IsarService.instance.getAllCategories();
});

final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return IsarService.instance.getExpenseCategories();
});

final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  return IsarService.instance.getIncomeCategories();
});

// Notifier to trigger refresh
class CategoriesNotifier extends StateNotifier<int> {
  CategoriesNotifier() : super(0);
  void refresh() => state++;
}

final categoriesRefreshProvider =
    StateNotifierProvider<CategoriesNotifier, int>(
        (ref) => CategoriesNotifier());

// ─── Transactions ───────────────────────────────────────────────
class TransactionsNotifier extends StateNotifier<int> {
  TransactionsNotifier() : super(0);
  void refresh() => state++;

  Future<void> saveWithBalance({
    Transaction? previous,
    required Transaction next,
    required AccountsNotifier accounts,
  }) async {
    await IsarService.instance.saveTransaction(next);
    try {
      await accounts.replaceTransaction(previous: previous, next: next);
    } catch (_) {
      if (previous == null) {
        await IsarService.instance.deleteTransaction(next.id);
      } else {
        await IsarService.instance.saveTransaction(previous);
      }
      rethrow;
    }
    refresh();
  }

  Future<void> deleteWithBalance({
    required Transaction transaction,
    required AccountsNotifier accounts,
  }) async {
    await IsarService.instance.deleteTransaction(transaction.id);
    try {
      await accounts.reverseTransaction(transaction);
    } catch (_) {
      await IsarService.instance.saveTransaction(transaction);
      rethrow;
    }
    refresh();
  }
}

final transactionsRefreshProvider =
    StateNotifierProvider<TransactionsNotifier, int>(
        (ref) => TransactionsNotifier());

final monthlyTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionsRefreshProvider); // rebuild on refresh
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getTransactionsByMonth(sm.year, sm.month);
});

final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  return IsarService.instance.getAllTransactions();
});

final favoriteTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  return IsarService.instance.getFavoriteTransactions();
});

// ─── Monthly Summary ────────────────────────────────────────────
final monthlySummaryProvider =
    FutureProvider<({double income, double expense, int count})>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getMonthlySummary(sm.year, sm.month);
});

// ─── Category Totals ────────────────────────────────────────────
final expenseCategoryTotalsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance
      .getCategoryTotals(sm.year, sm.month, TransactionType.expense);
});

final incomeCategoryTotalsProvider =
    FutureProvider<Map<String, double>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance
      .getCategoryTotals(sm.year, sm.month, TransactionType.income);
});

final expenseCategoryTrendProvider =
    FutureProvider<List<({int year, int month, Map<String, double> totals})>>(
        (ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getCategoryTotalsTrend(sm.year, sm.month);
});

// ─── Daily totals ────────────────────────────────────────────────
final dailyTotalsProvider = FutureProvider<Map<int, double>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getDailyTotals(sm.year, sm.month);
});

// ─── Budgets ────────────────────────────────────────────────────
class BudgetsNotifier extends StateNotifier<int> {
  BudgetsNotifier() : super(0);
  void refresh() => state++;
}

final budgetsRefreshProvider =
    StateNotifierProvider<BudgetsNotifier, int>((ref) => BudgetsNotifier());

final monthlyBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  ref.watch(budgetsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getBudgetsByMonth(sm.year, sm.month);
});

// ─── Savings Goals ───────────────────────────────────────────────
class SavingsNotifier extends StateNotifier<int> {
  SavingsNotifier() : super(0);
  void refresh() => state++;
}

final savingsRefreshProvider =
    StateNotifierProvider<SavingsNotifier, int>((ref) => SavingsNotifier());

final savingsGoalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  ref.watch(savingsRefreshProvider);
  return IsarService.instance.getAllSavingsGoals();
});

// ─── Recurring Transactions ──────────────────────────────────────
class RecurringNotifier extends StateNotifier<int> {
  RecurringNotifier() : super(0);
  void refresh() => state++;
}

final recurringRefreshProvider =
    StateNotifierProvider<RecurringNotifier, int>((ref) => RecurringNotifier());

final recurringProvider =
    FutureProvider<List<RecurringTransaction>>((ref) async {
  ref.watch(recurringRefreshProvider);
  return IsarService.instance.getAllRecurring();
});

// ─── Search ──────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return [];
  final filter = ref.watch(transactionFilterProvider);
  final results = await IsarService.instance.searchTransactions(q.trim());
  if (filter.accountIds.isEmpty) return results;
  return results
      .where((transaction) =>
          filter.accountIds.contains(transaction.paymentAccountId))
      .toList();
});

// ─── Transaction filter state ────────────────────────────────────
class TransactionFilter {
  final int? categoryId;
  final PaymentMethod? paymentMethod;
  final Set<String> accountIds;
  final TransactionType? type;
  final String? sortBy; // 'date', 'amount'
  final bool sortDesc;

  const TransactionFilter({
    this.categoryId,
    this.paymentMethod,
    this.accountIds = const {},
    this.type,
    this.sortBy = 'date',
    this.sortDesc = true,
  });

  TransactionFilter copyWith({
    int? categoryId,
    bool clearCategory = false,
    PaymentMethod? paymentMethod,
    bool clearPayment = false,
    Set<String>? accountIds,
    TransactionType? type,
    bool clearType = false,
    String? sortBy,
    bool? sortDesc,
  }) {
    return TransactionFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      paymentMethod:
          clearPayment ? null : (paymentMethod ?? this.paymentMethod),
      accountIds: accountIds ?? this.accountIds,
      type: clearType ? null : (type ?? this.type),
      sortBy: sortBy ?? this.sortBy,
      sortDesc: sortDesc ?? this.sortDesc,
    );
  }

  bool get hasActiveFilter =>
      categoryId != null ||
      paymentMethod != null ||
      accountIds.isNotEmpty ||
      type != null;
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final filteredTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final txns = await ref.watch(monthlyTransactionsProvider.future);
  final filter = ref.watch(transactionFilterProvider);

  var result = txns.where((t) {
    if (filter.categoryId != null && t.categoryId != filter.categoryId)
      return false;
    if (filter.paymentMethod != null && t.paymentMethod != filter.paymentMethod)
      return false;
    if (filter.accountIds.isNotEmpty &&
        !filter.accountIds.contains(t.paymentAccountId)) return false;
    if (filter.type != null && t.type != filter.type) return false;
    return true;
  }).toList();

  if (filter.sortBy == 'amount') {
    result.sort((a, b) => filter.sortDesc
        ? b.amount.compareTo(a.amount)
        : a.amount.compareTo(b.amount));
  } else {
    result.sort((a, b) =>
        filter.sortDesc ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
  }

  return result;
});

// ─── Phase 2: Trend data (6 months) ─────────────────────────────
final monthlyTrendProvider = FutureProvider<
    List<({int year, int month, double expense, double income})>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getMonthlyTrend(sm.year, sm.month);
});

// ─── Phase 2: Weekday totals ─────────────────────────────────────
final weekdayTotalsProvider = FutureProvider<Map<int, double>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getWeekdayTotals(sm.year, sm.month);
});

// ─── Phase 2: Top expenses ───────────────────────────────────────
final topExpensesProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionsRefreshProvider);
  final sm = ref.watch(selectedMonthProvider);
  return IsarService.instance.getTopExpenses(sm.year, sm.month);
});

// ─── Phase 2: All-time stats ─────────────────────────────────────
final allTimeStatsProvider = FutureProvider<
    ({
      double totalSpent,
      double totalIncome,
      int totalTxns,
      double avgMonthlySpend
    })>((ref) async {
  ref.watch(transactionsRefreshProvider);
  return IsarService.instance.getAllTimeStats();
});

// ─── Phase 2: Spending limit ──────────────────────────────────────
final spendingLimitProvider = StateProvider<double?>((ref) => null);

// ─── Phase 2: PIN lock state ─────────────────────────────────────
final pinStateProvider = StateProvider<String?>((ref) => null);
final appUnlockedProvider = StateProvider<bool>((ref) => true);

// ─── Phase 3: Theme mode ─────────────────────────────────────────
// 'dark' | 'light' | 'system'
final themeModeProvider = StateProvider<String>((ref) => 'dark');

// ─── Phase 3: Accounts ───────────────────────────────────────────
class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier() : super([]);

  void load(List<Account> accounts) => state = accounts;

  Future<void> save(List<Account> accounts) async {
    state = accounts;
    await AppPrefs.instance.setAccountsJson(accountsToJson(accounts));
  }

  Future<void> addAccount(Account account) async {
    await save([...state, account]);
  }

  Future<void> updateAccount(Account updated) async {
    await save(state.map((a) => a.id == updated.id ? updated : a).toList());
  }

  Future<void> deleteAccount(String id) async {
    await save(state.where((a) => a.id != id).toList());
  }

  double get totalBalance => state.fold(0.0, (sum, a) => sum + a.balance);

  Account? accountById(String? id) {
    if (id == null) return null;
    for (final account in state) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<void> _applyBalanceDelta(String accountId, double delta) async {
    final account = accountById(accountId);
    if (account == null) return;
    await updateAccount(account.copyWith(balance: account.balance + delta));
  }

  Future<void> applyTransaction(Transaction txn) async {
    final delta = txn.type == TransactionType.income ? txn.amount : -txn.amount;
    if (txn.paymentAccountId == null) return;
    await _applyBalanceDelta(txn.paymentAccountId!, delta);
  }

  Future<void> reverseTransaction(Transaction txn) async {
    final delta = txn.type == TransactionType.income ? -txn.amount : txn.amount;
    if (txn.paymentAccountId == null) return;
    await _applyBalanceDelta(txn.paymentAccountId!, delta);
  }

  Future<void> replaceTransaction(
      {Transaction? previous, required Transaction next}) async {
    if (previous != null) {
      await reverseTransaction(previous);
    }
    await applyTransaction(next);
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>(
    (ref) => AccountsNotifier());

// ─── Phase 3: Transfers ──────────────────────────────────────────
class TransfersNotifier extends StateNotifier<List<AccountTransfer>> {
  TransfersNotifier() : super([]);

  void load(List<AccountTransfer> transfers) => state = transfers;

  Future<void> addTransfer(AccountTransfer transfer) async {
    final updated = [...state, transfer];
    state = updated;
    await AppPrefs.instance.setTransfersJson(transfersToJson(updated));
  }
}

final transfersProvider =
    StateNotifierProvider<TransfersNotifier, List<AccountTransfer>>(
        (ref) => TransfersNotifier());

// ─── Phase 3: Notifications enabled ─────────────────────────────
final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

final currencyRefreshProvider = StateProvider<int>((ref) => 0);

// ─── Net worth history ───────────────────────────────────────────
typedef NetWorthPoint = ({DateTime date, double balance});

class NetWorthNotifier extends StateNotifier<List<NetWorthPoint>> {
  NetWorthNotifier() : super([]);

  void load(List<NetWorthPoint> history) => state = history;

  /// Records today's total balance, replacing any existing entry for today.
  /// Keeps at most the most recent 180 days locally.
  Future<void> recordSnapshot(double balance) async {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final withoutToday =
        state.where((e) => !_isSameDay(e.date, todayKey)).toList();
    final updated = [...withoutToday, (date: todayKey, balance: balance)]
      ..sort((a, b) => a.date.compareTo(b.date));
    final trimmed =
        updated.length > 180 ? updated.sublist(updated.length - 180) : updated;
    state = trimmed;
    await AppPrefs.instance.setNetWorthHistoryJson(_encode(trimmed));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _encode(List<NetWorthPoint> items) => json.encode(items
      .map((e) => {'date': e.date.toIso8601String(), 'balance': e.balance})
      .toList());
}

final netWorthHistoryProvider =
    StateNotifierProvider<NetWorthNotifier, List<NetWorthPoint>>(
        (ref) => NetWorthNotifier());

List<NetWorthPoint> netWorthHistoryFromJson(String raw) {
  try {
    final list = json.decode(raw) as List;
    return list
        .map((e) => (
              date: DateTime.parse(e['date'] as String),
              balance: (e['balance'] as num).toDouble(),
            ))
        .toList();
  } catch (_) {
    return [];
  }
}

// ─── Pending notification transactions ─────────────────────────
class PendingTransactionsNotifier
    extends StateNotifier<List<PendingTransaction>> {
  PendingTransactionsNotifier() : super([]);

  Future<void> loadSaved() async {
    final raw = AppPrefs.instance.get<String>('pending_transactions') ?? '[]';
    state = pendingTransactionsFromJson(raw);
  }

  Future<void> _persist() async {
    await AppPrefs.instance.set(
      'pending_transactions',
      pendingTransactionsToJson(state),
    );
  }

  Future<void> ingestCaptured(List<CapturedNotification> notifications) async {
    final existingIds = state.map((item) => item.id).toSet();
    final additions = <PendingTransaction>[];

    for (final notification in notifications) {
      final sourceId =
          '${notification.packageName}_${notification.receivedAt.millisecondsSinceEpoch}';
      if (existingIds.contains(sourceId)) continue;

      final accountHint = notification.title.trim().isEmpty
          ? notification.packageName
          : notification.title.trim();
      final parsed = TransactionSmsParser.parse(
        notification.message,
        accountName: accountHint,
        now: notification.receivedAt,
      );
      if (parsed == null) continue;

      additions.add(PendingTransaction.fromParsed(
        parsed: parsed,
        sourcePackage: notification.packageName,
        accountHint: accountHint,
        sourceId: sourceId,
      ));
    }

    if (additions.isEmpty) return;
    state = [...state, ...additions];
    await _persist();
  }

  Future<void> syncFromAndroid() async {
    try {
      if (!AppPrefs.instance.notificationCaptureEnabled) return;
      final captureService = NotificationCaptureService();
      if (!await captureService.isAccessEnabled()) return;
      final captured = await captureService.readCaptured();
      await ingestCaptured(captured);
      await captureService.clearCaptured();
    } catch (_) {
      // Notification capture is optional and unavailable on non-Android builds.
    }
  }

  Future<void> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _persist();
  }
}

final pendingTransactionsProvider = StateNotifierProvider<
    PendingTransactionsNotifier, List<PendingTransaction>>(
  (ref) => PendingTransactionsNotifier(),
);
