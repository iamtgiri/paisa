import 'package:isar/isar.dart';

part 'recurring.g.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

@collection
class RecurringTransaction {
  Id id = Isar.autoIncrement;

  late String title;
  late double amount;
  late int categoryId;
  late String categoryName;
  late int categoryColor;
  late String categoryIcon;
  late bool isExpense;
  late String paymentMethod;
  late String note;

  @enumerated
  late RecurringFrequency frequency;

  late DateTime nextDueDate;
  late DateTime createdAt;
  late bool isActive;

  RecurringTransaction();

  factory RecurringTransaction.create({
    required String title,
    required double amount,
    required int categoryId,
    required String categoryName,
    required int categoryColor,
    required String categoryIcon,
    required bool isExpense,
    required String paymentMethod,
    required RecurringFrequency frequency,
    required DateTime nextDueDate,
    String note = '',
  }) {
    final r = RecurringTransaction();
    r.title = title;
    r.amount = amount;
    r.categoryId = categoryId;
    r.categoryName = categoryName;
    r.categoryColor = categoryColor;
    r.categoryIcon = categoryIcon;
    r.isExpense = isExpense;
    r.paymentMethod = paymentMethod;
    r.frequency = frequency;
    r.nextDueDate = nextDueDate;
    r.note = note;
    r.createdAt = DateTime.now();
    r.isActive = true;
    return r;
  }

  DateTime computeNextDue() {
    switch (frequency) {
      case RecurringFrequency.daily:
        return nextDueDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        final m = nextDueDate.month + 1;
        final y = nextDueDate.year + (m > 12 ? 1 : 0);
        return DateTime(y, m > 12 ? 1 : m, nextDueDate.day);
      case RecurringFrequency.yearly:
        return DateTime(
            nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
    }
  }
}
