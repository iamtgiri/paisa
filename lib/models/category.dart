import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;
  late int colorValue; // Color.value stored as int
  late String icon; // icon codePoint as hex string e.g. 'e25a'
  late bool isExpense; // true = expense category, false = income category
  late bool isDefault; // default categories cannot be deleted
  bool? isEnabled; // null keeps legacy categories enabled
  late DateTime createdAt;

  Category();

  factory Category.create({
    required String name,
    required int colorValue,
    required String icon,
    required bool isExpense,
    bool isDefault = false,
    bool isEnabled = true,
  }) {
    final c = Category();
    c.name = name;
    c.colorValue = colorValue;
    c.icon = icon;
    c.isExpense = isExpense;
    c.isDefault = isDefault;
    c.isEnabled = isEnabled;
    c.createdAt = DateTime.now();
    return c;
  }

  Category copyWith({
    String? name,
    int? colorValue,
    String? icon,
    bool? isExpense,
    bool? isEnabled,
  }) {
    final c = Category();
    c.id = id;
    c.name = name ?? this.name;
    c.colorValue = colorValue ?? this.colorValue;
    c.icon = icon ?? this.icon;
    c.isExpense = isExpense ?? this.isExpense;
    c.isDefault = isDefault;
    c.isEnabled = isEnabled ?? this.isEnabled;
    c.createdAt = createdAt;
    return c;
  }

  bool get enabled => isEnabled != false;
}
