import 'package:isar/isar.dart';

part 'transaction.g.dart';

enum PaymentMethod {
  cash,
  upi,
  debitCard,
  creditCard,
  netBanking,
  other,
}

enum TransactionType {
  expense,
  income,
}

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;
  late int categoryId;
  late String categoryName; // denormalized for fast display
  late int categoryColor; // denormalized
  late String categoryIcon; // denormalized
  late DateTime date;
  late String description;

  /// Selected account used to pay for this transaction.
  /// Null keeps older transactions compatible.
  String? paymentAccountId;

  @enumerated
  late PaymentMethod paymentMethod;

  @enumerated
  late TransactionType type;

  late List<String> tags;
  late bool isFavorite;
  DateTime? createdAt;

  Transaction();

  factory Transaction.create({
    required double amount,
    required int categoryId,
    required String categoryName,
    required int categoryColor,
    required String categoryIcon,
    required DateTime date,
    required String description,
    String? paymentAccountId,
    required PaymentMethod paymentMethod,
    required TransactionType type,
    List<String>? tags,
    bool isFavorite = false,
  }) {
    final t = Transaction();
    t.amount = amount;
    t.categoryId = categoryId;
    t.categoryName = categoryName;
    t.categoryColor = categoryColor;
    t.categoryIcon = categoryIcon;
    t.date = date;
    t.description = description;
    t.paymentAccountId = paymentAccountId;
    t.paymentMethod = paymentMethod;
    t.type = type;
    t.tags = tags ?? [];
    t.isFavorite = isFavorite;
    t.createdAt = DateTime.now();
    return t;
  }

  Transaction copyWith({
    double? amount,
    int? categoryId,
    String? categoryName,
    int? categoryColor,
    String? categoryIcon,
    DateTime? date,
    String? description,
    String? paymentAccountId,
    PaymentMethod? paymentMethod,
    TransactionType? type,
    List<String>? tags,
    bool? isFavorite,
  }) {
    final t = Transaction();
    t.id = id;
    t.amount = amount ?? this.amount;
    t.categoryId = categoryId ?? this.categoryId;
    t.categoryName = categoryName ?? this.categoryName;
    t.categoryColor = categoryColor ?? this.categoryColor;
    t.categoryIcon = categoryIcon ?? this.categoryIcon;
    t.date = date ?? this.date;
    t.description = description ?? this.description;
    t.paymentAccountId = paymentAccountId ?? this.paymentAccountId;
    t.paymentMethod = paymentMethod ?? this.paymentMethod;
    t.type = type ?? this.type;
    t.tags = tags ?? List.from(this.tags);
    t.isFavorite = isFavorite ?? this.isFavorite;
    t.createdAt = createdAt;
    return t;
  }

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
}
