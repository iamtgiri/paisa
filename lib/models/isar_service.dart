import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/recurring.dart';

class IsarService {
  late Isar _isar;
  static IsarService? _instance;

  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  IsarService._();

  Isar get db => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        CategorySchema,
        TransactionSchema,
        BudgetSchema,
        SavingsGoalSchema,
        RecurringTransactionSchema,
      ],
      directory: dir.path,
      name: 'paisa_db',
    );
    await _seedDefaultCategories();
  }

  Future<void> _seedDefaultCategories() async {
    final count = await _isar.categorys.count();
    if (count > 0) return;

    final defaults = _defaultCategories();
    await _isar.writeTxn(() async {
      for (final cat in defaults) {
        await _isar.categorys.put(cat);
      }
    });
  }

  List<Category> _defaultCategories() {
    // ── EXPENSE CATEGORIES ──────────────────────────────────────
    // Grouped: Daily Life → Work & Commute → Housing & Bills →
    //          Finance & EMI → Family & Health → Personal → General
    final expenseCategories = [
      // Daily Life
      ('Food & Dining', 0xFFE53935, 'e25a'), // restaurant
      ('Groceries', 0xFF43A047, 'e1fc'), // shopping_basket
      ('Coffee & Snacks', 0xFF795548, 'efef'), // coffee
      ('Alcohol', 0xFFD81B60, 'eb3c'), // local_bar

      // Work & Commute
      ('Office Commute', 0xFF1E88E5, 'e531'), // directions_car
      ('Train / Metro', 0xFF1565C0, 'e570'), // train
      ('Fuel', 0xFFFF6F00, 'e546'), // local_gas_station
      ('Cab / Auto', 0xFF039BE5, 'e558'), // local_taxi
      ('Work Meals', 0xFFFF7043, 'e25a'), // restaurant

      // Housing & Bills
      ('Rent', 0xFF5D4037, 'e88a'), // home
      ('Electricity', 0xFF546E7A, 'e1db'), // power
      ('Water Bill', 0xFF0288D1, 'e798'), // water_drop
      ('Gas / Cooking', 0xFFFF8F00, 'e546'), // local_gas_station
      ('Internet', 0xFF00838F, 'e63e'), // wifi
      ('Mobile Recharge', 0xFF7B1FA2, 'e0cd'), // phone_android
      ('OTT / Streaming', 0xFFE91E63, 'e40b'), // movie

      // Finance & EMI
      ('Home Loan EMI', 0xFF3949AB, 'e88a'), // home
      ('Car Loan EMI', 0xFF1E88E5, 'e531'), // directions_car
      ('Personal Loan EMI', 0xFFD32F2F, 'e8b1'), // account_balance
      ('Credit Card Bill', 0xFF880E4F, 'e870'), // credit_card
      ('SIP / Mutual Fund', 0xFF00695C, 'e8dc'), // trending_up
      ('Stocks / Trading', 0xFF2E7D32, 'e8dc'), // trending_up
      ('Insurance Premium', 0xFF37474F, 'e1db'), // security / power icon

      // Family & Health
      ('Family Support', 0xFFF06292, 'e87d'), // favorite / heart
      ('Child Education', 0xFF558B2F, 'e80c'), // school
      ('Child Care', 0xFFAD1457, 'e91d'), // child_care / pets
      ('Medical', 0xFFD32F2F, 'e548'), // local_hospital
      ('Medicines', 0xFFE53935, 'e54f'), // medication / local_pharmacy
      ('Gym / Fitness', 0xFF00897B, 'ea26'), // fitness_center
      ('Home Trips', 0xFF039BE5, 'e145'), // flight (home visits)

      // Personal
      ('Personal Care', 0xFFF48FB1, 'e31a'), // spa
      ('Clothing', 0xFF8E24AA, 'e8cc'), // shopping_bag
      ('Shopping', 0xFF6A1B9A, 'e8cc'), // shopping_bag
      ('Entertainment', 0xFFFF6F00, 'e40b'), // movie
      ('Books & Learning', 0xFF1B5E20, 'e865'), // book / menu_book
      ('Subscriptions', 0xFF4527A0, 'e870'), // card_membership

      // Travel & Leisure
      ('Travel', 0xFF01579B, 'e145'), // flight
      ('Hotel / Stay', 0xFF33691E, 'e549'), // hotel
      ('Weekend Outing', 0xFFEF6C00, 'ea26'), // sports / explore

      // General
      ('Education', 0xFF00897B, 'e80c'), // school
      ('Gifts', 0xFFAD1457, 'e8f6'), // card_giftcard
      ('Pet Care', 0xFF6D4C41, 'e91d'), // pets
      ('Miscellaneous', 0xFF757575, 'e8b8'), // more_horiz
    ];

    // ── INCOME CATEGORIES ──────────────────────────────────────
    final incomeCategories = [
      // Primary
      ('Salary', 0xFF2E7D32, 'e227'), // account_balance_wallet
      ('Bonus', 0xFF1B5E20, 'e8dc'), // trending_up
      ('Arrears', 0xFF388E3C, 'e8b1'), // reply / received

      // Investments & Returns
      ('SIP Returns', 0xFF00695C, 'e8dc'), // trending_up
      ('Stock Dividend', 0xFF004D40, 'e8dc'), // trending_up
      ('Fixed Deposit', 0xFF01579B, 'e2d6'), // account_balance
      ('Rental Income', 0xFF4E342E, 'e88a'), // home

      // Side Income
      ('Freelancing', 0xFF1565C0, 'e8f9'), // work
      ('Consulting', 0xFF283593, 'e0af'), // business_center
      ('Business Income', 0xFF6A1B9A, 'e0af'), // business_center
      ('Part-time Work', 0xFF4527A0, 'e8f9'), // work

      // Cashbacks & Refunds
      ('Cashback', 0xFF558B2F, 'e8b1'), // reply
      ('Refund', 0xFFAD1457, 'e8b1'), // reply
      ('Tax Refund', 0xFF00838F, 'e2d6'), // account_balance

      // Family & Others
      ('Family Transfer', 0xFFF57F17, 'e87d'), // favorite
      ('Gift Received', 0xFFE91E63, 'e8f6'), // card_giftcard
      ('Scholarship', 0xFF558B2F, 'e80c'), // school
      ('Other Income', 0xFF37474F, 'e8b8'), // more_horiz
    ];

    final List<Category> cats = [];
    for (final e in expenseCategories) {
      cats.add(Category.create(
        name: e.$1,
        colorValue: e.$2,
        icon: e.$3,
        isExpense: true,
        isDefault: true,
      ));
    }
    for (final e in incomeCategories) {
      cats.add(Category.create(
        name: e.$1,
        colorValue: e.$2,
        icon: e.$3,
        isExpense: false,
        isDefault: true,
      ));
    }
    return cats;
  }

  // ─── Categories ────────────────────────────────────────────
  Future<List<Category>> getAllCategories() async {
    return _isar.categorys.where().sortByName().findAll();
  }

  Future<List<Category>> getExpenseCategories() async {
    final categories = await _isar.categorys
        .filter()
        .isExpenseEqualTo(true)
        .sortByName()
        .findAll();
    return categories.where((category) => category.enabled).toList();
  }

  Future<List<Category>> getIncomeCategories() async {
    final categories = await _isar.categorys
        .filter()
        .isExpenseEqualTo(false)
        .sortByName()
        .findAll();
    return categories.where((category) => category.enabled).toList();
  }

  Future<void> saveCategory(Category cat) async {
    await _isar.writeTxn(() => _isar.categorys.put(cat));
  }

  Future<void> setCategoryEnabled(int id, bool enabled) async {
    final category = await _isar.categorys.get(id);
    if (category == null) return;
    category.isEnabled = enabled;
    await saveCategory(category);
  }

  Future<void> deleteCategory(int id) async {
    await _isar.writeTxn(() => _isar.categorys.delete(id));
  }

  /// Adds any default categories that aren't already present by name.
  /// Safe to call repeatedly — won't create duplicates.
  Future<int> reseedMissingDefaults() async {
    final existing = await getAllCategories();
    final existingNames = existing.map((c) => c.name).toSet();
    final defaults = _defaultCategories()
        .where((c) => !existingNames.contains(c.name))
        .toList();
    if (defaults.isEmpty) return 0;
    await _isar.writeTxn(() async {
      for (final cat in defaults) {
        await _isar.categorys.put(cat);
      }
    });
    return defaults.length;
  }

  // ─── Transactions ───────────────────────────────────────────
  Future<List<Transaction>> getAllTransactions() async {
    return _isar.transactions.where().sortByDateDesc().findAll();
  }

  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end =
        DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
    return _isar.transactions
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
      DateTime from, DateTime to) async {
    return _isar.transactions
        .filter()
        .dateBetween(from, to)
        .sortByDateDesc()
        .findAll();
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    final q = query.toLowerCase();
    final all = await getAllTransactions();
    return all.where((t) {
      return t.description.toLowerCase().contains(q) ||
          t.categoryName.toLowerCase().contains(q) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q)) ||
          t.amount.toString().contains(q);
    }).toList();
  }

  Future<List<Transaction>> getFavoriteTransactions() async {
    return _isar.transactions
        .filter()
        .isFavoriteEqualTo(true)
        .sortByDateDesc()
        .findAll();
  }

  Future<void> saveTransaction(Transaction txn) async {
    await _isar.writeTxn(() => _isar.transactions.put(txn));
  }

  Future<void> deleteTransaction(int id) async {
    await _isar.writeTxn(() => _isar.transactions.delete(id));
  }

  // ─── Budgets ────────────────────────────────────────────────
  Future<List<Budget>> getBudgetsByMonth(int year, int month) async {
    return _isar.budgets
        .filter()
        .yearEqualTo(year)
        .and()
        .monthEqualTo(month)
        .findAll();
  }

  Future<void> saveBudget(Budget budget) async {
    await _isar.writeTxn(() => _isar.budgets.put(budget));
  }

  Future<List<Budget>> getAllBudgets() async {
    return _isar.budgets.where().findAll();
  }

  Future<void> deleteBudget(int id) async {
    await _isar.writeTxn(() => _isar.budgets.delete(id));
  }

  // ─── Savings Goals ──────────────────────────────────────────
  Future<List<SavingsGoal>> getAllSavingsGoals() async {
    return _isar.savingsGoals.where().sortByCreatedAt().findAll();
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    await _isar.writeTxn(() => _isar.savingsGoals.put(goal));
  }

  Future<void> deleteSavingsGoal(int id) async {
    await _isar.writeTxn(() => _isar.savingsGoals.delete(id));
  }

  // ─── Recurring Transactions ──────────────────────────────────
  Future<List<RecurringTransaction>> getAllRecurring() async {
    return _isar.recurringTransactions.where().findAll();
  }

  Future<void> saveRecurring(RecurringTransaction r) async {
    await _isar.writeTxn(() => _isar.recurringTransactions.put(r));
  }

  Future<void> deleteRecurring(int id) async {
    await _isar.writeTxn(() => _isar.recurringTransactions.delete(id));
  }

  Future<void> clearUserData() async {
    await _isar.writeTxn(() async {
      await _isar.transactions.clear();
      await _isar.budgets.clear();
      await _isar.savingsGoals.clear();
      await _isar.recurringTransactions.clear();
      await _isar.categorys.clear();
    });
  }

  // ─── Analytics helpers ───────────────────────────────────────
  Future<Map<String, double>> getCategoryTotals(
      int year, int month, TransactionType type) async {
    final txns = await getTransactionsByMonth(year, month);
    final result = <String, double>{};
    for (final t in txns.where((t) => t.type == type)) {
      result[t.categoryName] =
          (result[t.categoryName] ?? 0.0) + t.amount.toDouble();
    }
    return result;
  }

  Future<List<({int year, int month, Map<String, double> totals})>>
      getCategoryTotalsTrend(int year, int month,
          {TransactionType type = TransactionType.expense,
          int months = 6}) async {
    final result = <({int year, int month, Map<String, double> totals})>[];
    int y = year;
    int m = month;
    for (int i = 0; i < months - 1; i++) {
      m--;
      if (m == 0) {
        m = 12;
        y--;
      }
    }
    for (int i = 0; i < months; i++) {
      result.add((
        year: y,
        month: m,
        totals: await getCategoryTotals(y, m, type),
      ));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return result;
  }

  Future<Map<int, double>> getDailyTotals(int year, int month) async {
    final txns = await getTransactionsByMonth(year, month);
    final result = <int, double>{};
    for (final t in txns.where((t) => t.isExpense)) {
      result[t.date.day] = (result[t.date.day] ?? 0) + t.amount;
    }
    return result;
  }

  // ─── Summary ─────────────────────────────────────────────────
  Future<({double income, double expense, int count})> getMonthlySummary(
      int year, int month) async {
    final txns = await getTransactionsByMonth(year, month);
    double income = 0;
    double expense = 0;
    for (final t in txns) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return (income: income, expense: expense, count: txns.length);
  }

  // ─── 6-month trend ───────────────────────────────────────────
  /// Returns list of 6 monthly summaries ending at [year]/[month],
  /// newest last so it renders left→right on a line chart.
  Future<List<({int year, int month, double expense, double income})>>
      getMonthlyTrend(int year, int month, {int months = 6}) async {
    final result = <({int year, int month, double expense, double income})>[];
    int y = year;
    int m = month;
    // Walk back (months-1) steps then collect forward
    for (int i = 0; i < months - 1; i++) {
      m--;
      if (m == 0) {
        m = 12;
        y--;
      }
    }
    for (int i = 0; i < months; i++) {
      final summary = await getMonthlySummary(y, m);
      result.add((
        year: y,
        month: m,
        expense: summary.expense,
        income: summary.income
      ));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return result;
  }

  // ─── Weekday analysis ────────────────────────────────────────
  /// Returns total expense per weekday (1=Mon … 7=Sun) for given month.
  Future<Map<int, double>> getWeekdayTotals(int year, int month) async {
    final txns = await getTransactionsByMonth(year, month);
    final result = <int, double>{};
    for (final t in txns.where((t) => t.isExpense)) {
      // DateTime.weekday: 1=Monday, 7=Sunday
      final wd = t.date.weekday;
      result[wd] = (result[wd] ?? 0) + t.amount;
    }
    return result;
  }

  // ─── Top expenses ────────────────────────────────────────────
  Future<List<Transaction>> getTopExpenses(int year, int month,
      {int limit = 10}) async {
    final txns = await getTransactionsByMonth(year, month);
    final expenses = txns.where((t) => t.isExpense).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.take(limit).toList();
  }

  // ─── All-time stats ──────────────────────────────────────────
  Future<
      ({
        double totalSpent,
        double totalIncome,
        int totalTxns,
        double avgMonthlySpend
      })> getAllTimeStats() async {
    final all = await getAllTransactions();
    if (all.isEmpty) {
      return (
        totalSpent: 0.0,
        totalIncome: 0.0,
        totalTxns: 0,
        avgMonthlySpend: 0.0
      );
    }
    double spent = 0;
    double income = 0;
    final months = <String>{};
    for (final t in all) {
      if (t.isExpense) {
        spent += t.amount;
      } else {
        income += t.amount;
      }
      months.add('${t.date.year}-${t.date.month}');
    }
    final avg = months.isEmpty ? 0.0 : spent / months.length;
    return (
      totalSpent: spent,
      totalIncome: income,
      totalTxns: all.length,
      avgMonthlySpend: avg
    );
  }

  // ─── Export ──────────────────────────────────────────────────
  Future<List<Transaction>> getAllForExport() async {
    return _isar.transactions.where().sortByDate().findAll();
  }

  Future<void> close() async {
    await _isar.close();
  }
}
