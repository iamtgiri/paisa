import 'dart:convert';

/// A named money account (Cash, SBI, HDFC, Paytm Wallet, etc.)
/// Stored as a JSON list in AppPrefs — no Isar schema needed since
/// users typically have 2-6 accounts and we never query them.
class Account {
  final String id; // uuid-like string
  String name;
  double balance;
  int colorValue;
  String icon; // MaterialIcons hex codepoint
  bool isDefault;

  Account({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorValue,
    required this.icon,
    this.isDefault = false,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        balance: (j['balance'] as num).toDouble(),
        colorValue: j['colorValue'] as int,
        icon: j['icon'] as String,
        isDefault: j['isDefault'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'colorValue': colorValue,
        'icon': icon,
        'isDefault': isDefault,
      };

  Account copyWith({
    String? name,
    double? balance,
    int? colorValue,
    String? icon,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        balance: balance ?? this.balance,
        colorValue: colorValue ?? this.colorValue,
        icon: icon ?? this.icon,
        isDefault: isDefault,
      );

  double get displayBalance => balance;

  bool get isCash => name.trim().toLowerCase() == 'cash';
}

/// Transfer record between two accounts (also stored in AppPrefs)
class AccountTransfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final DateTime date;
  final String note;

  AccountTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory AccountTransfer.fromJson(Map<String, dynamic> j) => AccountTransfer(
        id: j['id'] as String,
        fromAccountId: j['fromAccountId'] as String,
        toAccountId: j['toAccountId'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        note: j['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };
}

/// Helper to encode/decode a list of accounts from JSON string
List<Account> accountsFromJson(String raw) {
  try {
    final list = json.decode(raw) as List;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

String accountsToJson(List<Account> accounts) =>
    json.encode(accounts.map((a) => a.toJson()).toList());

List<AccountTransfer> transfersFromJson(String raw) {
  try {
    final list = json.decode(raw) as List;
    return list
        .map((e) => AccountTransfer.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

String transfersToJson(List<AccountTransfer> transfers) =>
    json.encode(transfers.map((t) => t.toJson()).toList());
