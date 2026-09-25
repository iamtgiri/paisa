import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../../models/app_prefs.dart';
import '../../models/account.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/isar_service.dart';
import '../../models/recurring.dart';
import '../../models/savings_goal.dart';
import '../../models/transaction.dart';
import '../../providers/providers.dart';
import '../../screens/accounts/accounts_screen.dart';
import '../../screens/reports/monthly_report_screen.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_utils.dart';
import '../../widgets/shared_widgets.dart';
import '../lock/pin_lock_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinStateProvider);
    final limit = ref.watch(spendingLimitProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notifEnabled = ref.watch(notificationsEnabledProvider);
    final currency = AppPrefs.instance.currencySymbol;
    final currencyPrefix = AppPrefs.instance.currencyPrefix;
    final currencyDecimals = AppPrefs.instance.currencyDecimals;
    ref.watch(currencyRefreshProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'BUDGETS & GOALS', [
            _tile(
                context,
                Icons.pie_chart_outline,
                'Monthly Budgets',
                'Set spending limits per category',
                AppTheme.primary,
                () => _push(context, const BudgetsScreen())),
            _tile(
                context,
                Icons.savings_outlined,
                'Savings Goals',
                'Track your savings targets',
                const Color(0xFF4CAF50),
                () => _push(context, const SavingsGoalsScreen())),
            _tile(
                context,
                Icons.repeat_rounded,
                'Recurring Transactions',
                'Auto-reminders for fixed expenses',
                const Color(0xFF6C63FF),
                () => _push(context, const RecurringScreen())),
          ]),
          const SizedBox(height: 16),
          _section(context, 'ACCOUNTS & REPORTS', [
            _tile(
              context,
              Icons.account_balance_wallet_outlined,
              'Accounts',
              'Track cash, bank and wallet balances',
              const Color(0xFF1E88E5),
              () => _push(context, const AccountsScreen()),
            ),
            _tile(
              context,
              Icons.summarize_outlined,
              'Monthly Report',
              'Full summary for the selected month',
              const Color(0xFF00897B),
              () => _push(context, const MonthlyReportScreen()),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'SPENDING CONTROL', [
            _tile(
              context,
              Icons.shield_outlined,
              'Monthly Spending Limit',
              limit != null
                  ? 'Limit: ${AppUtils.formatAmount(limit, compact: true)}'
                  : 'Set a monthly cap to control spending',
              const Color(0xFFFF9800),
              () => _showSpendingLimitSheet(context, ref, limit),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'PREFERENCES', [
            _tileWithTrailing(
              context,
              Icons.palette_outlined,
              'Theme',
              'Appearance of the app',
              const Color(0xFF9C27B0),
              _ThemeToggle(
                current: themeMode,
                onChanged: (mode) async {
                  ref.read(themeModeProvider.notifier).state = mode;
                  await AppPrefs.instance.setThemeMode(mode);
                },
              ),
            ),
            _tileWithTrailing(
              context,
              Icons.notifications_outlined,
              'Notifications',
              'Alerts and spending reports',
              const Color(0xFFFF9800),
              Switch(
                value: notifEnabled,
                onChanged: (v) async {
                  ref.read(notificationsEnabledProvider.notifier).state = v;
                  await AppPrefs.instance.setNotificationsEnabled(v);
                  if (v) {
                    await NotificationService.instance.init();
                    await NotificationService.instance.checkAndNotify();
                  } else {
                    await NotificationService.instance.cancelAll();
                  }
                },
              ),
            ),
            _tile(
              context,
              Icons.insights_outlined,
              'Spending reports',
              'Daily, weekly and monthly summaries',
              const Color(0xFF00897B),
              () => _showNotificationSettingsSheet(context, ref),
            ),
            _tile(
              context,
              Icons.currency_exchange_rounded,
              'Currency & formatting',
              '$currency ${currencyPrefix ? 'prefix' : 'suffix'} · '
                  '${currencyDecimals == 0 ? 'No decimals' : '2 decimals'}',
              AppTheme.primary,
              () => _showCurrencySheet(context, ref),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'SECURITY', [
            _tile(
              context,
              Icons.lock_outline_rounded,
              pin != null ? 'Change / Remove PIN' : 'Set App PIN',
              pin != null
                  ? 'PIN lock is enabled'
                  : 'Protect app with a 4-digit PIN',
              const Color(0xFF6C63FF),
              () => _handlePin(context, ref, pin),
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, 'DATA', [
            _tile(
                context,
                Icons.upload_outlined,
                'Export CSV',
                'Share your transactions as a spreadsheet',
                const Color(0xFF00897B),
                () => _exportCsv(context, ref)),
            _tile(
                context,
                Icons.download_outlined,
                'Export JSON Backup',
                'Full backup of all your data',
                const Color(0xFF1E88E5),
                () => _exportJson(context, ref)),
            _tile(
                context,
                Icons.restore_outlined,
                'Import JSON Backup',
                'Restore from a previous backup',
                Color(0xFFFF6B6B),
                () => _importJson(context, ref)),
            _tile(
                context,
                Icons.category_outlined,
                'Add Missing Categories',
                'Add newly available default categories',
                context.appColors.onSurfaceMuted,
                () => _reseedCategories(context, ref)),
          ]),
          SizedBox(height: 16),
          _section(context, 'INFO', [
            _tile(
                context,
                Icons.info_outline,
                'About Paisa',
                'Version 1.2.0 — Personal finance tracker',
                context.appColors.onSurfaceMuted,
                () => _showAbout(context)),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(title,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurfaceMuted,
                  letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: tiles.asMap().entries.map((e) {
              final isLast = e.key == tiles.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 11, color: context.appColors.onSurfaceMuted)),
      trailing: Icon(Icons.chevron_right,
          size: 18, color: context.appColors.onSurfaceMuted),
      onTap: onTap,
    );
  }

  Widget _tileWithTrailing(BuildContext context, IconData icon, String title,
      String subtitle, Color color, Widget trailing) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 11, color: context.appColors.onSurfaceMuted)),
      trailing: trailing,
    );
  }

  Future<void> _showNotificationSettingsSheet(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final prefs = AppPrefs.instance;

          Future<void> update(
              Future<void> Function(bool) save, bool value) async {
            await save(value);
            setSheetState(() {});
            if (value && prefs.notificationsEnabled) {
              await NotificationService.instance.init();
              await NotificationService.instance.checkAndNotify();
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetContext.appColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Spending reports',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Reports are generated locally when the app is opened after a period ends.',
                  style: TextStyle(
                      fontSize: 12,
                      color: sheetContext.appColors.onSurfaceMuted),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily report'),
                  subtitle:
                      const Text('Yesterday compared with the day before'),
                  value: prefs.dailyReportNotifications,
                  onChanged: (value) =>
                      update(prefs.setDailyReportNotifications, value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weekly report'),
                  subtitle: const Text(
                      'Sunday night, or the next time you open the app'),
                  value: prefs.weeklyReportNotifications,
                  onChanged: (value) =>
                      update(prefs.setWeeklyReportNotifications, value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monthly report'),
                  subtitle: const Text(
                      'Last night of the month, or the next app open'),
                  value: prefs.monthlyReportNotifications,
                  onChanged: (value) =>
                      update(prefs.setMonthlyReportNotifications, value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showCurrencySheet(BuildContext context, WidgetRef ref) async {
    var symbol = AppPrefs.instance.currencySymbol;
    var prefix = AppPrefs.instance.currencyPrefix;
    var decimals = AppPrefs.instance.currencyDecimals;
    final symbols = ['₹', r'$', '€', '£', '¥', '₱', r'R$'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Currency & formatting',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('SYMBOL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.onSurfaceMuted,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: symbols
                    .map((item) => ChoiceChip(
                          label: Text(item),
                          selected: symbol == item,
                          onSelected: (_) => setState(() => symbol = item),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Prefix')),
                  ButtonSegment(value: false, label: Text('Suffix')),
                ],
                selected: {prefix},
                onSelectionChanged: (value) =>
                    setState(() => prefix = value.first),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 2, label: Text('₹1,250.00')),
                  ButtonSegment(value: 0, label: Text('₹1,250')),
                ],
                selected: {decimals},
                onSelectionChanged: (value) =>
                    setState(() => decimals = value.first),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await AppPrefs.instance.setCurrencySymbol(symbol);
                  await AppPrefs.instance.setCurrencyPrefix(prefix);
                  await AppPrefs.instance.setCurrencyDecimals(decimals);
                  AppUtils.configureCurrency(
                      symbol: symbol, prefix: prefix, decimals: decimals);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.read(currencyRefreshProvider.notifier).state++;
                },
                child: const Text('Save formatting'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final txns = await IsarService.instance.getAllForExport();
      if (txns.isEmpty) {
        _snack(context, 'No transactions to export');
        return;
      }
      final rows = [
        [
          'Date',
          'Type',
          'Category',
          'Description',
          'Amount',
          'Payment Method',
          'Tags'
        ],
        ...txns.map((t) => [
              DateFormat('yyyy-MM-dd').format(t.date),
              t.isExpense ? 'Expense' : 'Income',
              t.categoryName,
              t.description,
              t.amount.toStringAsFixed(2),
              AppUtils.paymentMethodLabel(t.paymentMethod),
              t.tags.join('; '),
            ]),
      ];
      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/paisa_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Paisa Transactions Export');
    } catch (e) {
      _snack(context, 'Export failed: $e');
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    try {
      final txns = await IsarService.instance.getAllForExport();
      final cats = await IsarService.instance.getAllCategories();
      final goals = await IsarService.instance.getAllSavingsGoals();
      final budgets = await IsarService.instance.getAllBudgets();
      final recurring = await IsarService.instance.getAllRecurring();
      final accounts = ref.read(accountsProvider);
      final transfers = ref.read(transfersProvider);
      final preferences = AppPrefs.instance.exportData();
      preferences.remove('pin');

      final data = {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'preferences': preferences,
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'transfers': transfers.map((t) => t.toJson()).toList(),
        'transactions': txns
            .map((t) => {
                  'id': t.id,
                  'amount': t.amount,
                  'categoryId': t.categoryId,
                  'categoryName': t.categoryName,
                  'categoryColor': t.categoryColor,
                  'categoryIcon': t.categoryIcon,
                  'date': t.date.toIso8601String(),
                  'description': t.description,
                  'paymentAccountId': t.paymentAccountId,
                  'paymentMethod': t.paymentMethod.index,
                  'type': t.type.index,
                  'tags': t.tags,
                  'isFavorite': t.isFavorite,
                  'createdAt': t.createdAt?.toIso8601String(),
                })
            .toList(),
        'categories': cats
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'colorValue': c.colorValue,
                  'icon': c.icon,
                  'isExpense': c.isExpense,
                  'isDefault': c.isDefault,
                  'isEnabled': c.enabled,
                  'createdAt': c.createdAt.toIso8601String(),
                })
            .toList(),
        'budgets': budgets
            .map((b) => {
                  'id': b.id,
                  'categoryId': b.categoryId,
                  'categoryName': b.categoryName,
                  'categoryColor': b.categoryColor,
                  'categoryIcon': b.categoryIcon,
                  'limitAmount': b.limitAmount,
                  'month': b.month,
                  'year': b.year,
                })
            .toList(),
        'savingsGoals': goals
            .map((g) => {
                  'id': g.id,
                  'name': g.name,
                  'targetAmount': g.targetAmount,
                  'currentAmount': g.currentAmount,
                  'colorValue': g.colorValue,
                  'icon': g.icon,
                  'deadline': g.deadline?.toIso8601String(),
                  'isCompleted': g.isCompleted,
                  'createdAt': g.createdAt.toIso8601String(),
                })
            .toList(),
        'recurringTransactions': recurring
            .map((r) => {
                  'id': r.id,
                  'title': r.title,
                  'amount': r.amount,
                  'categoryId': r.categoryId,
                  'categoryName': r.categoryName,
                  'categoryColor': r.categoryColor,
                  'categoryIcon': r.categoryIcon,
                  'isExpense': r.isExpense,
                  'paymentMethod': r.paymentMethod,
                  'note': r.note,
                  'frequency': r.frequency.index,
                  'nextDueDate': r.nextDueDate.toIso8601String(),
                  'createdAt': r.createdAt.toIso8601String(),
                  'isActive': r.isActive,
                })
            .toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/paisa_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], text: 'Paisa Backup');
    } catch (e) {
      _snack(context, 'Backup failed: $e');
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text(
            'This will replace current Paisa data with the selected backup, including accounts, balances, transactions, budgets and preferences.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
              child: const Text('Import')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      await IsarService.instance.clearUserData();

      // Restore categories first so transaction and budget IDs remain valid.
      final cats = data['categories'] as List? ?? [];
      for (final c in cats) {
        final cat = Category()
          ..name = c['name'] as String
          ..colorValue = c['colorValue'] as int
          ..icon = c['icon'] as String
          ..isExpense = c['isExpense'] as bool
          ..isDefault = c['isDefault'] as bool? ?? false
          ..isEnabled = c['isEnabled'] as bool? ?? true
          ..createdAt = c['createdAt'] != null
              ? DateTime.parse(c['createdAt'] as String)
              : DateTime.now();
        if (c['id'] is int) cat.id = c['id'] as int;
        await IsarService.instance.saveCategory(cat);
      }
      await IsarService.instance.reseedMissingDefaults();

      // Import transactions
      final txns = data['transactions'] as List? ?? [];
      for (final t in txns) {
        final txn = Transaction.create(
          amount: (t['amount'] as num).toDouble(),
          categoryId: t['categoryId'] as int,
          categoryName: t['categoryName'] as String,
          categoryColor: t['categoryColor'] as int,
          categoryIcon: t['categoryIcon'] as String,
          date: DateTime.parse(t['date'] as String),
          description: t['description'] as String,
          paymentAccountId: t['paymentAccountId'] as String?,
          paymentMethod: PaymentMethod.values[t['paymentMethod'] as int],
          type: TransactionType.values[t['type'] as int],
          tags: List<String>.from(t['tags'] ?? []),
          isFavorite: t['isFavorite'] as bool? ?? false,
        )..createdAt = t['createdAt'] != null
            ? DateTime.parse(t['createdAt'] as String)
            : null;
        if (t['id'] is int) txn.id = t['id'] as int;
        await IsarService.instance.saveTransaction(txn);
      }

      final budgets = data['budgets'] as List? ?? [];
      for (final b in budgets) {
        final budget = Budget.create(
          categoryId: b['categoryId'] as int,
          categoryName: b['categoryName'] as String,
          categoryColor: b['categoryColor'] as int,
          categoryIcon: b['categoryIcon'] as String,
          limitAmount: (b['limitAmount'] as num).toDouble(),
          month: b['month'] as int,
          year: b['year'] as int,
        );
        if (b['id'] is int) budget.id = b['id'] as int;
        await IsarService.instance.saveBudget(budget);
      }

      // Import savings goals
      final goals = data['savingsGoals'] as List? ?? [];
      for (final g in goals) {
        final goal = SavingsGoal.create(
          name: g['name'],
          targetAmount: (g['targetAmount'] as num).toDouble(),
          colorValue: g['colorValue'] as int,
          icon: g['icon'] as String,
          deadline:
              g['deadline'] != null ? DateTime.parse(g['deadline']) : null,
        )..createdAt = g['createdAt'] != null
            ? DateTime.parse(g['createdAt'] as String)
            : DateTime.now();
        if (g['id'] is int) goal.id = g['id'] as int;
        goal.currentAmount = (g['currentAmount'] as num).toDouble();
        goal.isCompleted = g['isCompleted'] as bool? ?? false;
        await IsarService.instance.saveSavingsGoal(goal);
      }

      final recurring = data['recurringTransactions'] as List? ?? [];
      for (final r in recurring) {
        final item = RecurringTransaction.create(
          title: r['title'] as String,
          amount: (r['amount'] as num).toDouble(),
          categoryId: r['categoryId'] as int,
          categoryName: r['categoryName'] as String,
          categoryColor: r['categoryColor'] as int,
          categoryIcon: r['categoryIcon'] as String,
          isExpense: r['isExpense'] as bool,
          paymentMethod: r['paymentMethod'] as String,
          frequency: RecurringFrequency.values[r['frequency'] as int],
          nextDueDate: DateTime.parse(r['nextDueDate'] as String),
          note: r['note'] as String? ?? '',
        )
          ..createdAt = r['createdAt'] != null
              ? DateTime.parse(r['createdAt'] as String)
              : DateTime.now()
          ..isActive = r['isActive'] as bool? ?? true;
        if (r['id'] is int) item.id = r['id'] as int;
        await IsarService.instance.saveRecurring(item);
      }

      final accounts = (data['accounts'] as List? ?? [])
          .map((a) => Account.fromJson(a as Map<String, dynamic>))
          .toList();
      final transfers = (data['transfers'] as List? ?? [])
          .map((t) => AccountTransfer.fromJson(t as Map<String, dynamic>))
          .toList();
      ref.read(accountsProvider.notifier).load(accounts);
      ref.read(transfersProvider.notifier).load(transfers);
      final preferences = data['preferences'];
      if (preferences is Map<String, dynamic>) {
        final localPin = AppPrefs.instance.pin;
        final restoredPreferences = Map<String, dynamic>.from(preferences);
        if (localPin == null) {
          restoredPreferences.remove('pin');
        } else {
          restoredPreferences['pin'] = localPin;
        }
        await AppPrefs.instance.replaceData(restoredPreferences);
        ref.read(spendingLimitProvider.notifier).state =
            AppPrefs.instance.spendingLimit;
        ref.read(themeModeProvider.notifier).state =
            AppPrefs.instance.themeMode;
        ref.read(notificationsEnabledProvider.notifier).state =
            AppPrefs.instance.notificationsEnabled;
        ref.read(pinStateProvider.notifier).state = localPin;
      }

      ref.read(transactionsRefreshProvider.notifier).refresh();
      ref.invalidate(categoriesProvider);
      ref.read(categoriesRefreshProvider.notifier).refresh();
      ref.read(budgetsRefreshProvider.notifier).refresh();
      ref.read(savingsRefreshProvider.notifier).refresh();
      ref.read(recurringRefreshProvider.notifier).refresh();

      if (context.mounted) {
        _snack(context,
            'Restored ${txns.length} transactions, ${accounts.length} accounts and all saved data');
      }
    } catch (e) {
      if (context.mounted) _snack(context, 'Import failed: $e');
    }
  }

  Future<void> _showSpendingLimitSheet(
      BuildContext context, WidgetRef ref, double? current) async {
    final ctrl = TextEditingController(
        text: current != null ? current.toStringAsFixed(0) : '');
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final kb = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(builder: (ctx2, setState) {
          return Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
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
                Text('Monthly Spending Limit',
                    style: Theme.of(ctx2).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                    'Get a warning on the Insights tab when you approach or exceed this amount.',
                    style: TextStyle(
                        fontSize: 12, color: context.appColors.onSurfaceMuted)),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit',
                    prefixText: '₹ ',
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (current != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx2, -1.0),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.expense,
                            side: const BorderSide(color: AppTheme.expense),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Remove'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final v = double.tryParse(ctrl.text);
                          Navigator.pop(ctx2, v);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );

    if (result == null) return;
    if (result == -1.0) {
      await AppPrefs.instance.setSpendingLimit(null);
      ref.read(spendingLimitProvider.notifier).state = null;
      if (context.mounted) _snack(context, 'Spending limit removed');
    } else if (result > 0) {
      await AppPrefs.instance.setSpendingLimit(result);
      ref.read(spendingLimitProvider.notifier).state = result;
      if (context.mounted) {
        _snack(context,
            'Limit set to ${AppUtils.formatAmount(result, compact: true)}/month');
      }
    }
  }

  Future<void> _handlePin(
      BuildContext context, WidgetRef ref, String? currentPin) async {
    if (currentPin != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PIN Lock'),
          content: const Text('Your app is currently protected with a PIN.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'remove'),
              child: const Text('Remove PIN',
                  style: TextStyle(color: AppTheme.expense)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'change'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
              child: const Text('Change'),
            ),
          ],
        ),
      );
      if (action == 'remove') {
        await AppPrefs.instance.setPin(null);
        ref.read(pinStateProvider.notifier).state = null;
        if (context.mounted) _snack(context, 'PIN removed');
      } else if (action == 'change' && context.mounted) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PinSetupScreen()));
      }
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PinSetupScreen()));
    }
  }

  Future<void> _reseedCategories(BuildContext context, WidgetRef ref) async {
    final added = await IsarService.instance.reseedMissingDefaults();
    ref.invalidate(categoriesProvider);
    ref.invalidate(expenseCategoriesProvider);
    ref.invalidate(incomeCategoriesProvider);
    if (context.mounted) {
      _snack(
          context,
          added > 0
              ? 'Added $added new categories'
              : 'All categories are already up to date');
    }
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            const Text('Paisa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.2.0',
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted)),
            const SizedBox(height: 16),
            const Text(
              'A personal, offline-first finance tracker built for real life — '
              'tracking expenses, budgets, investments and savings without ads or cloud.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: context.appColors.divider),
            const SizedBox(height: 16),
            Text('Built with',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.onSurfaceMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _aboutChip(context, 'Flutter & Dart'),
            const SizedBox(height: 4),
            _aboutChip(context, 'Isar Database'),
            const SizedBox(height: 4),
            _aboutChip(context, 'Riverpod · fl_chart · Google Fonts'),
            const SizedBox(height: 16),
            Divider(height: 1, color: context.appColors.divider),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.onSurfaceMuted,
                    height: 1.6),
                children: [
                  TextSpan(text: 'Designed & assembled by '),
                  TextSpan(
                    text: 'Tanmoy Giri',
                    style: TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' — with a lot of help from AI tools '
                        'and the open-source Flutter ecosystem.\n'
                        'No ads. No tracking. Your data stays on your phone.',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _aboutChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: context.appColors.onSurface,
              fontWeight: FontWeight.w500)),
    );
  }

  void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ═══════════════════════════════════════════════
// BUDGETS SCREEN
// ═══════════════════════════════════════════════
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sm = ref.watch(selectedMonthProvider);
    final budgetsAsync = ref.watch(monthlyBudgetsProvider);
    final expTotals = ref.watch(expenseCategoryTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets — ${AppUtils.formatMonthYear(sm.year, sm.month)}'),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No budgets set',
              subtitle: 'Tap + to set a budget for a category',
              action: ElevatedButton.icon(
                onPressed: () => _showBudgetSheet(context, ref, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Budget'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final b = budgets[i];
              return expTotals.when(
                data: (totals) {
                  final spent = totals[b.categoryName] ?? 0;
                  return _BudgetCard(
                    budget: b,
                    spent: spent,
                    onEdit: () => _showBudgetSheet(context, ref, b),
                    onDelete: () async {
                      await IsarService.instance.deleteBudget(b.id);
                      ref.read(budgetsRefreshProvider.notifier).refresh();
                    },
                  );
                },
                loading: () => _BudgetCard(
                    budget: b, spent: 0, onEdit: () {}, onDelete: () {}),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          );
        },
        loading: () => const ShimmerList(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget_fab',
        onPressed: () => _showBudgetSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showBudgetSheet(
      BuildContext context, WidgetRef ref, Budget? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetFormSheet(existing: existing),
    );
    ref.read(budgetsRefreshProvider.notifier).refresh();
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard(
      {required this.budget,
      required this.spent,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final b = budget;
    final color = AppUtils.colorFromValue(b.categoryColor);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CategoryBadge(
                  icon: b.categoryIcon, colorValue: b.categoryColor, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.categoryName,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.appColors.onSurface)),
                    Text(
                        'Budget: ${AppUtils.formatAmount(b.limitAmount, compact: true)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.onSurfaceMuted)),
                  ],
                ),
              ),
              IconButton(
                  icon: Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  color: context.appColors.onSurfaceMuted),
              IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: onDelete,
                  color: AppTheme.expense.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 10),
          BudgetProgressBar(spent: spent, limit: b.limitAmount, color: color),
        ],
      ),
    );
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final Budget? existing;
  const _BudgetFormSheet({this.existing});

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _amountCtrl = TextEditingController();
  Category? _selectedCat;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _amountCtrl.text = widget.existing!.limitAmount.toStringAsFixed(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCats());
  }

  Future<void> _loadCats() async {
    final cats = await IsarService.instance.getExpenseCategories();
    if (!mounted) return;
    setState(() {
      if (widget.existing != null) {
        _selectedCat =
            cats.where((c) => c.id == widget.existing!.categoryId).firstOrNull;
      }
      _selectedCat ??= cats.firstOrNull;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final catsAsync = ref.watch(expenseCategoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
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
          Text(widget.existing == null ? 'Set Budget' : 'Edit Budget',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          // Category picker
          Text('CATEGORY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurfaceMuted,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          catsAsync.when(
            data: (cats) => SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => CategoryChip(
                  category: cats[i],
                  selected: _selectedCat?.id == cats[i].id,
                  onTap: () => setState(() => _selectedCat = cats[i]),
                ),
              ),
            ),
            loading: () => const SizedBox(height: 46),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Amount
          Text('MONTHLY LIMIT (₹)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.onSurfaceMuted,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: '₹ ',
            ),
            autofocus: widget.existing != null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text(
                    widget.existing == null ? 'Set Budget' : 'Update Budget'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_selectedCat == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }

    setState(() => _saving = true);
    final sm = ref.read(selectedMonthProvider);
    final cat = _selectedCat!;

    Budget budget;
    if (widget.existing != null) {
      budget = widget.existing!.copyWith(limitAmount: amount);
    } else {
      budget = Budget.create(
        categoryId: cat.id,
        categoryName: cat.name,
        categoryColor: cat.colorValue,
        categoryIcon: cat.icon,
        limitAmount: amount,
        month: sm.month,
        year: sm.year,
      );
    }

    await IsarService.instance.saveBudget(budget);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════
// SAVINGS GOALS SCREEN
// ═══════════════════════════════════════════════
class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'No savings goals',
              subtitle: 'Create a goal and track your progress',
              action: ElevatedButton.icon(
                onPressed: () => _showGoalSheet(context, ref, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Goal'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _GoalCard(
              goal: goals[i],
              onEdit: () => _showGoalSheet(context, ref, goals[i]),
              onAddFunds: () => _showAddFunds(context, ref, goals[i]),
              onDelete: () async {
                await IsarService.instance.deleteSavingsGoal(goals[i].id);
                ref.read(savingsRefreshProvider.notifier).refresh();
              },
            ),
          );
        },
        loading: () => const ShimmerList(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goal_fab',
        onPressed: () => _showGoalSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showGoalSheet(
      BuildContext context, WidgetRef ref, SavingsGoal? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalFormSheet(existing: existing),
    );
    ref.read(savingsRefreshProvider.notifier).refresh();
  }

  Future<void> _showAddFunds(
      BuildContext context, WidgetRef ref, SavingsGoal goal) async {
    final ctrl = TextEditingController();
    final confirm = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '0', prefixText: '₹ '),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', ''));
              Navigator.pop(ctx, v);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirm != null && confirm > 0) {
      goal.currentAmount =
          (goal.currentAmount + confirm).clamp(0.0, goal.targetAmount);
      goal.isCompleted = goal.currentAmount >= goal.targetAmount;
      await IsarService.instance.saveSavingsGoal(goal);
      ref.read(savingsRefreshProvider.notifier).refresh();
    }
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;

  const _GoalCard(
      {required this.goal,
      required this.onEdit,
      required this.onAddFunds,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final color = AppUtils.colorFromValue(g.colorValue);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: g.isCompleted
            ? Border.all(color: AppTheme.income.withOpacity(0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(AppUtils.iconFromHex(g.icon), size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(g.name,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.onSurface),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (g.isCompleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.income.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Achieved!',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.income,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    if (g.deadline != null)
                      Text('By ${DateFormat('d MMM y').format(g.deadline!)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.onSurfaceMuted)),
                  ],
                ),
              ),
              IconButton(
                  icon: Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  color: context.appColors.onSurfaceMuted),
              IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: onDelete,
                  color: AppTheme.expense.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppUtils.formatAmount(g.currentAmount, compact: true),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
              Text(
                'of ${AppUtils.formatAmount(g.targetAmount, compact: true)}',
                style: TextStyle(
                    fontSize: 12, color: context.appColors.onSurfaceMuted),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: g.progress,
              backgroundColor: context.appColors.surfaceCard2,
              valueColor: AlwaysStoppedAnimation<Color>(
                  g.isCompleted ? AppTheme.income : color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(g.progress * 100).toStringAsFixed(0)}% saved',
                style: TextStyle(
                    fontSize: 11, color: context.appColors.onSurfaceMuted),
              ),
              if (!g.isCompleted)
                TextButton.icon(
                  onPressed: onAddFunds,
                  icon: const Icon(Icons.add, size: 14),
                  label:
                      const Text('Add Funds', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalFormSheet extends ConsumerStatefulWidget {
  final SavingsGoal? existing;
  const _GoalFormSheet({this.existing});

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  int _selectedColor = 0xFF00BFA5;
  String _selectedIcon = 'e838';
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _targetCtrl.text = e.targetAmount.toStringAsFixed(0);
      _selectedColor = e.colorValue;
      _selectedIcon = e.icon;
      _deadline = e.deadline;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
      child: SingleChildScrollView(
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
            Text(isEdit ? 'Edit Goal' : 'New Goal',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            // Preview icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(_selectedColor).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(AppUtils.iconFromHex(_selectedIcon),
                    size: 32, color: Color(_selectedColor)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g. New Laptop',
                prefixIcon: Icon(Icons.flag_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                hintText: '0',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            // Color
            _label('COLOR'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: AppUtils.categoryColors.map((c) {
                final sel = _selectedColor == c.$2;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.$2),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(c.$2),
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(
                              color: context.appColors.onSurface, width: 2.5)
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Icon
            _label('ICON'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppUtils.categoryIcons.take(16).map((ic) {
                final sel = _selectedIcon == ic.$2;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic.$2),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sel
                          ? Color(_selectedColor).withOpacity(0.15)
                          : context.appColors.surfaceCard2,
                      borderRadius: BorderRadius.circular(10),
                      border: sel
                          ? Border.all(color: Color(_selectedColor), width: 1.5)
                          : null,
                    ),
                    child: Icon(AppUtils.iconFromHex(ic.$2),
                        size: 18,
                        color: sel
                            ? Color(_selectedColor)
                            : context.appColors.onSurfaceMuted),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            // Deadline
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceCard2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 16, color: context.appColors.onSurfaceMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'No deadline (optional)'
                            : 'By ${DateFormat('d MMM y').format(_deadline!)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: _deadline == null
                                ? context.appColors.onSurfaceMuted
                                : context.appColors.onSurface),
                      ),
                    ),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: Icon(Icons.close,
                            size: 16, color: context.appColors.onSurfaceMuted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(isEdit ? 'Update Goal' : 'Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: context.appColors.onSurfaceMuted,
          letterSpacing: 0.8));

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '')) ?? 0;
    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a name and target amount')));
      return;
    }
    setState(() => _saving = true);

    if (widget.existing != null) {
      final g = widget.existing!;
      g.name = name;
      g.targetAmount = target;
      g.colorValue = _selectedColor;
      g.icon = _selectedIcon;
      g.deadline = _deadline;
      await IsarService.instance.saveSavingsGoal(g);
    } else {
      final goal = SavingsGoal.create(
        name: name,
        targetAmount: target,
        colorValue: _selectedColor,
        icon: _selectedIcon,
        deadline: _deadline,
      );
      await IsarService.instance.saveSavingsGoal(goal);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════
// RECURRING TRANSACTIONS SCREEN
// ═══════════════════════════════════════════════
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurAsync = ref.watch(recurringProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      body: recurAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.repeat_rounded,
              title: 'No recurring set',
              subtitle: 'Set up reminders for rent, bills, subscriptions',
              action: ElevatedButton.icon(
                onPressed: () => _showSheet(context, ref, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Recurring'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(180, 44)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _RecurringTile(
              item: items[i],
              onDelete: () async {
                await IsarService.instance.deleteRecurring(items[i].id);
                ref.read(recurringRefreshProvider.notifier).refresh();
              },
              onToggle: () async {
                items[i].isActive = !items[i].isActive;
                await IsarService.instance.saveRecurring(items[i]);
                ref.read(recurringRefreshProvider.notifier).refresh();
              },
              onAddNow: () async {
                final r = items[i];
                final cats = r.isExpense
                    ? await IsarService.instance.getExpenseCategories()
                    : await IsarService.instance.getIncomeCategories();
                final cat = cats.where((c) => c.id == r.categoryId).firstOrNull;
                if (cat == null) return;
                final txn = Transaction.create(
                  amount: r.amount,
                  categoryId: r.categoryId,
                  categoryName: r.categoryName,
                  categoryColor: r.categoryColor,
                  categoryIcon: r.categoryIcon,
                  date: DateTime.now(),
                  description: r.title,
                  paymentMethod: PaymentMethod.values.firstWhere(
                    (m) => AppUtils.paymentMethodLabel(m) == r.paymentMethod,
                    orElse: () => PaymentMethod.other,
                  ),
                  type: r.isExpense
                      ? TransactionType.expense
                      : TransactionType.income,
                );
                await IsarService.instance.saveTransaction(txn);
                r.nextDueDate = r.computeNextDue();
                await IsarService.instance.saveRecurring(r);
                ref.read(transactionsRefreshProvider.notifier).refresh();
                ref.read(recurringRefreshProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction added!')),
                  );
                }
              },
            ),
          );
        },
        loading: () => const ShimmerList(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recur_fab',
        onPressed: () => _showSheet(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context, WidgetRef ref,
      RecurringTransaction? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringFormSheet(existing: existing),
    );
    ref.read(recurringRefreshProvider.notifier).refresh();
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringTransaction item;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onAddNow;

  const _RecurringTile({
    required this.item,
    required this.onDelete,
    required this.onToggle,
    required this.onAddNow,
  });

  @override
  Widget build(BuildContext context) {
    final r = item;
    final color = AppUtils.colorFromValue(r.categoryColor);
    final isDue = r.nextDueDate.isBefore(DateTime.now()) ||
        r.nextDueDate.day == DateTime.now().day;

    return Opacity(
      opacity: r.isActive ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: isDue && r.isActive
              ? Border.all(color: AppTheme.primary.withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            CategoryBadge(
                icon: r.categoryIcon, colorValue: r.categoryColor, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.onSurface),
                      overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      Text(
                        '${AppUtils.formatAmount(r.amount, compact: true)} · ${_freqLabel(r.frequency)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                  Text(
                    isDue
                        ? 'Due today!'
                        : 'Next: ${AppUtils.formatDate(r.nextDueDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDue
                          ? AppTheme.primary
                          : context.appColors.onSurfaceMuted,
                      fontWeight: isDue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDue && r.isActive)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: onAddNow,
                    color: AppTheme.primary,
                    tooltip: 'Add now',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                Switch(
                  value: r.isActive,
                  onChanged: (_) => onToggle(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: onDelete,
                  color: AppTheme.expense.withOpacity(0.7),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ), // closes Container
    ); // closes Opacity
  }

  String _freqLabel(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  final RecurringTransaction? existing;
  const _RecurringFormSheet({this.existing});

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isExpense = true;
  Category? _selectedCat;
  RecurringFrequency _freq = RecurringFrequency.monthly;
  PaymentMethod _payment = PaymentMethod.upi;
  DateTime _nextDue = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _isExpense = e.isExpense;
      _freq = e.frequency;
      _nextDue = e.nextDueDate;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCats());
  }

  Future<void> _loadCats() async {
    final cats = _isExpense
        ? await IsarService.instance.getExpenseCategories()
        : await IsarService.instance.getIncomeCategories();
    if (!mounted) return;
    setState(() {
      _selectedCat = cats.firstOrNull;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final catsAsync = _isExpense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + kb),
      child: SingleChildScrollView(
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
            Text('Recurring Transaction',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Netflix, Rent, Mobile Recharge',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            // Type
            _label('TYPE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _typeBtn(true, 'Expense', AppTheme.expense)),
                const SizedBox(width: 10),
                Expanded(child: _typeBtn(false, 'Income', AppTheme.income)),
              ],
            ),
            const SizedBox(height: 16),
            // Category
            _label('CATEGORY'),
            const SizedBox(height: 8),
            catsAsync.when(
              data: (cats) => SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => CategoryChip(
                    category: cats[i],
                    selected: _selectedCat?.id == cats[i].id,
                    onTap: () => setState(() => _selectedCat = cats[i]),
                  ),
                ),
              ),
              loading: () => const SizedBox(height: 46),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            // Frequency
            _label('FREQUENCY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RecurringFrequency.values
                  .map((f) => ChoiceChip(
                        label: Text(_freqLabel(f)),
                        selected: _freq == f,
                        onSelected: (_) => setState(() => _freq = f),
                        selectedColor: AppTheme.primary.withOpacity(0.2),
                        side: BorderSide(
                          color: _freq == f
                              ? AppTheme.primary
                              : Colors.transparent,
                        ),
                        labelStyle: TextStyle(
                          color: _freq == f
                              ? AppTheme.primary
                              : context.appColors.onSurfaceMuted,
                          fontWeight:
                              _freq == f ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Save Recurring'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: context.appColors.onSurfaceMuted,
          letterSpacing: 0.8));

  Widget _typeBtn(bool isExp, String label, Color color) {
    final sel = _isExpense == isExp;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpense = isExp;
          _selectedCat = null;
        });
        _loadCats();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.12) : context.appColors.surfaceCard2,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: sel ? color : Colors.transparent, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: sel ? color : context.appColors.onSurfaceMuted,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
        ),
      ),
    );
  }

  String _freqLabel(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (title.isEmpty || amount <= 0 || _selectedCat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in title, amount and category')));
      return;
    }
    setState(() => _saving = true);
    final cat = _selectedCat!;
    final r = RecurringTransaction.create(
      title: title,
      amount: amount,
      categoryId: cat.id,
      categoryName: cat.name,
      categoryColor: cat.colorValue,
      categoryIcon: cat.icon,
      isExpense: _isExpense,
      paymentMethod: AppUtils.paymentMethodLabel(_payment),
      frequency: _freq,
      nextDueDate: _nextDue,
    );
    await IsarService.instance.saveRecurring(r);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ════════════════════════════════════════════════════════════════
// THEME TOGGLE WIDGET — 3-way: Dark / Light / System
// ════════════════════════════════════════════════════════════════
class _ThemeToggle extends StatelessWidget {
  final String current; // 'dark' | 'light' | 'system'
  final ValueChanged<String> onChanged;

  const _ThemeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(context, 'dark', Icons.dark_mode_outlined, 'Dark'),
          _btn(context, 'light', Icons.light_mode_outlined, 'Light'),
          _btn(context, 'system', Icons.contrast, 'Auto'),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String mode, IconData icon, String label) {
    final selected = current == mode;
    return GestureDetector(
      onTap: () => onChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: selected
              ? Border.all(color: AppTheme.primary.withOpacity(0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: selected
                    ? AppTheme.primary
                    : context.appColors.onSurfaceMuted),
            SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected
                        ? AppTheme.primary
                        : context.appColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}
