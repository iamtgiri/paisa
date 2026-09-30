import '../models/account.dart';
import '../models/app_prefs.dart';
import '../models/isar_service.dart';

class BackupService {
  const BackupService._();

  static Future<Map<String, dynamic>> buildData({
    required List<Account> accounts,
    required List<AccountTransfer> transfers,
  }) async {
    final txns = await IsarService.instance.getAllForExport();
    final cats = await IsarService.instance.getAllCategories();
    final goals = await IsarService.instance.getAllSavingsGoals();
    final budgets = await IsarService.instance.getAllBudgets();
    final recurring = await IsarService.instance.getAllRecurring();
    final preferences = AppPrefs.instance.exportData();
    preferences.remove('pin');

    return {
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
  }
}
