import 'dart:convert';

import 'transaction.dart';
import '../utils/transaction_sms_parser.dart';

class PendingTransaction {
  final String id;
  final String sourcePackage;
  final String accountHint;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String description;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? suggestedCategory;
  final String rawMessage;

  const PendingTransaction({
    required this.id,
    required this.sourcePackage,
    required this.accountHint,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
    required this.paymentMethod,
    required this.reference,
    required this.suggestedCategory,
    required this.rawMessage,
  });

  factory PendingTransaction.fromParsed({
    required ParsedNotificationTransaction parsed,
    required String sourcePackage,
    required String accountHint,
    required String sourceId,
  }) {
    return PendingTransaction(
      id: sourceId,
      sourcePackage: sourcePackage,
      accountHint: accountHint,
      amount: parsed.amount,
      type: parsed.type,
      date: parsed.date,
      description: parsed.description,
      paymentMethod: parsed.paymentMethod,
      reference: parsed.reference,
      suggestedCategory: parsed.suggestedCategory,
      rawMessage: parsed.rawMessage,
    );
  }

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    return PendingTransaction(
      id: json['id'] as String,
      sourcePackage: json['sourcePackage'] as String? ?? '',
      accountHint: json['accountHint'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type'] as int],
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      paymentMethod: PaymentMethod.values[json['paymentMethod'] as int],
      reference: json['reference'] as String?,
      suggestedCategory: json['suggestedCategory'] as String?,
      rawMessage: json['rawMessage'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourcePackage': sourcePackage,
        'accountHint': accountHint,
        'amount': amount,
        'type': type.index,
        'date': date.toIso8601String(),
        'description': description,
        'paymentMethod': paymentMethod.index,
        'reference': reference,
        'suggestedCategory': suggestedCategory,
        'rawMessage': rawMessage,
      };
}

List<PendingTransaction> pendingTransactionsFromJson(String raw) {
  try {
    final decoded = json.decode(raw) as List;
    return decoded
        .map((item) =>
            PendingTransaction.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  } catch (_) {
    return [];
  }
}

String pendingTransactionsToJson(List<PendingTransaction> items) =>
    json.encode(items.map((item) => item.toJson()).toList());
