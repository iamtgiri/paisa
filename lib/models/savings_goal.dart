import 'package:isar/isar.dart';

part 'savings_goal.g.dart';

@collection
class SavingsGoal {
  Id id = Isar.autoIncrement;

  late String name;
  late double targetAmount;
  late double currentAmount;
  late int colorValue;
  late String icon;
  DateTime? deadline;
  late DateTime createdAt;
  late bool isCompleted;

  SavingsGoal();

  factory SavingsGoal.create({
    required String name,
    required double targetAmount,
    required int colorValue,
    required String icon,
    DateTime? deadline,
  }) {
    final g = SavingsGoal();
    g.name = name;
    g.targetAmount = targetAmount;
    g.currentAmount = 0;
    g.colorValue = colorValue;
    g.icon = icon;
    g.deadline = deadline;
    g.createdAt = DateTime.now();
    g.isCompleted = false;
    return g;
  }

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);
}
