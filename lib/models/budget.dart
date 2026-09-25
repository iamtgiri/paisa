import 'package:isar/isar.dart';

part 'budget.g.dart';

@collection
class Budget {
  Id id = Isar.autoIncrement;

  late int categoryId;
  late String categoryName;
  late int categoryColor;
  late String categoryIcon;
  late double limitAmount;
  late int month; // 1-12
  late int year;

  Budget();

  factory Budget.create({
    required int categoryId,
    required String categoryName,
    required int categoryColor,
    required String categoryIcon,
    required double limitAmount,
    required int month,
    required int year,
  }) {
    final b = Budget();
    b.categoryId = categoryId;
    b.categoryName = categoryName;
    b.categoryColor = categoryColor;
    b.categoryIcon = categoryIcon;
    b.limitAmount = limitAmount;
    b.month = month;
    b.year = year;
    return b;
  }

  Budget copyWith({double? limitAmount}) {
    final b = Budget();
    b.id = id;
    b.categoryId = categoryId;
    b.categoryName = categoryName;
    b.categoryColor = categoryColor;
    b.categoryIcon = categoryIcon;
    b.limitAmount = limitAmount ?? this.limitAmount;
    b.month = month;
    b.year = year;
    return b;
  }
}
