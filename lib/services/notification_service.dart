import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_prefs.dart';
import '../models/isar_service.dart';
import '../models/transaction.dart';
import '../utils/app_utils.dart';

/// Wraps flutter_local_notifications.
/// Call [init] once after DB is ready (in main.dart addPostFrameCallback).
/// All notification IDs are deterministic so re-scheduling is idempotent.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'paisa_alerts';
  static const _channelName = 'Paisa Alerts';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    _initialized = true;

    // Request permission on Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Call this once on startup to fire any pending alerts.
  Future<void> checkAndNotify() async {
    if (!AppPrefs.instance.notificationsEnabled) return;
    await _checkRecurringDue();
    await _checkBudgetAlerts();
    await _checkPeriodReports();
  }

  Future<void> _checkPeriodReports() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefs = AppPrefs.instance;

    if (prefs.dailyReportNotifications) {
      final start = today.subtract(const Duration(days: 1));
      await _checkReport(
        id: 4001,
        title: 'Daily spending report',
        periodKey: _dateKey(start),
        lastPeriod: prefs.lastDailyReportPeriod,
        start: start,
        end: today,
        previousStart: start.subtract(const Duration(days: 1)),
        previousEnd: start,
        savePeriod: prefs.setLastDailyReportPeriod,
      );
    }

    if (prefs.weeklyReportNotifications) {
      final currentWeekStart = today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      );
      final isSundayNight = today.weekday == DateTime.sunday && now.hour >= 21;
      final isMondayCatchUp = today.weekday == DateTime.monday;
      if (isSundayNight || isMondayCatchUp) {
        final start = isSundayNight
            ? currentWeekStart
            : currentWeekStart.subtract(const Duration(days: 7));
        final end = isSundayNight
            ? today.add(const Duration(days: 1))
            : currentWeekStart;
        await _checkReport(
          id: 4002,
          title: 'Weekly spending report',
          periodKey: _dateKey(start),
          lastPeriod: prefs.lastWeeklyReportPeriod,
          start: start,
          end: end,
          previousStart: start.subtract(const Duration(days: 7)),
          previousEnd: start,
          savePeriod: prefs.setLastWeeklyReportPeriod,
        );
      }
    }

    if (prefs.monthlyReportNotifications) {
      final currentMonthStart = DateTime(today.year, today.month);
      final tomorrow = today.add(const Duration(days: 1));
      final isMonthEnd = tomorrow.month != today.month;
      final isMonthStart = today.day == 1;
      if ((isMonthEnd && now.hour >= 21) || isMonthStart) {
        final start = isMonthEnd
            ? currentMonthStart
            : DateTime(today.year, today.month - 1);
        final end = isMonthEnd
            ? DateTime(today.year, today.month + 1)
            : currentMonthStart;
        await _checkReport(
          id: 4003,
          title: 'Monthly spending report',
          periodKey: _dateKey(start),
          lastPeriod: prefs.lastMonthlyReportPeriod,
          start: start,
          end: end,
          previousStart: DateTime(start.year, start.month - 1),
          previousEnd: start,
          savePeriod: prefs.setLastMonthlyReportPeriod,
        );
      }
    }
  }

  Future<void> _checkReport({
    required int id,
    required String title,
    required String periodKey,
    required String? lastPeriod,
    required DateTime start,
    required DateTime end,
    required DateTime previousStart,
    required DateTime previousEnd,
    required Future<void> Function(String) savePeriod,
  }) async {
    if (lastPeriod == periodKey) return;

    final current = await _getSummary(start, end);
    final previous = await _getSummary(previousStart, previousEnd);
    await _show(
      id: id,
      title: title,
      body: _reportBody(current, previous),
      channel: _channelId,
      channelName: _channelName,
    );
    await savePeriod(periodKey);
  }

  Future<({double income, double expense})> _getSummary(
      DateTime start, DateTime end) async {
    final transactions = await IsarService.instance.getTransactionsByDateRange(
      start,
      end.subtract(const Duration(milliseconds: 1)),
    );
    double income = 0;
    double expense = 0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }
    return (income: income, expense: expense);
  }

  String _reportBody(({double income, double expense}) current,
      ({double income, double expense}) previous) {
    final change = current.expense - previous.expense;
    final comparison = previous.expense == 0
        ? current.expense == 0
            ? 'same as previous period'
            : 'no spending in previous period'
        : '${change.abs() / previous.expense * 100 >= 1 ? (change.abs() / previous.expense * 100).toStringAsFixed(0) : '<1'}% ${change > 0 ? 'higher' : change < 0 ? 'lower' : 'same'}';
    return 'Spent ${AppUtils.formatAmount(current.expense, compact: true)} · '
        '$comparison · income ${AppUtils.formatAmount(current.income, compact: true)}';
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ─── Recurring due today ──────────────────────────────────────
  Future<void> _checkRecurringDue() async {
    final items = await IsarService.instance.getAllRecurring();
    final today = DateTime.now();

    for (final r in items) {
      if (!r.isActive) continue;
      final due = r.nextDueDate;
      final isDueToday = due.year == today.year &&
          due.month == today.month &&
          due.day == today.day;
      final isOverdue =
          due.isBefore(DateTime(today.year, today.month, today.day));

      if (isDueToday || isOverdue) {
        await _show(
          id: 1000 + r.id,
          title: isDueToday
              ? '📅 ${r.title} is due today'
              : '⚠ ${r.title} is overdue',
          body:
              '${r.isExpense ? "Expense" : "Income"} of ₹${r.amount.toStringAsFixed(0)} — tap to add',
          channel: _channelId,
          channelName: _channelName,
        );
      }
    }
  }

  // ─── Budget alerts ────────────────────────────────────────────
  Future<void> _checkBudgetAlerts() async {
    final now = DateTime.now();
    final budgets =
        await IsarService.instance.getBudgetsByMonth(now.year, now.month);
    if (budgets.isEmpty) return;

    final totals = <String, double>{};
    final txns =
        await IsarService.instance.getTransactionsByMonth(now.year, now.month);
    for (final t in txns) {
      if (t.isExpense) {
        totals[t.categoryName] = (totals[t.categoryName] ?? 0) + t.amount;
      }
    }

    for (final b in budgets) {
      final spent = totals[b.categoryName] ?? 0;
      final pct = b.limitAmount > 0 ? spent / b.limitAmount : 0.0;

      if (pct >= 1.0) {
        await _show(
          id: 2000 + b.id,
          title: '🚨 ${b.categoryName} budget exceeded!',
          body:
              'Spent ₹${spent.toStringAsFixed(0)} of ₹${b.limitAmount.toStringAsFixed(0)} budget',
          channel: _channelId,
          channelName: _channelName,
        );
      } else if (pct >= 0.8) {
        await _show(
          id: 3000 + b.id,
          title:
              '⚠ ${b.categoryName} budget at ${(pct * 100).toStringAsFixed(0)}%',
          body:
              '₹${(b.limitAmount - spent).toStringAsFixed(0)} remaining this month',
          channel: _channelId,
          channelName: _channelName,
        );
      }
    }
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channel,
    required String channelName,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Cancel all notifications (e.g. when user disables them in settings)
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
