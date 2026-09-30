import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/models/pending_transaction.dart';
import 'package:paisa/models/transaction.dart';
import 'package:paisa/utils/transaction_sms_parser.dart';

void main() {
  test('maps a parsed notification into a persisted pending transaction', () {
    final parsed = TransactionSmsParser.parse(
      'Dear SBI User, your A/c X2425-credited by Rs.5 on 27Sep26 transfer '
      'from GOOGLE INDIA DIGITAL SERVICES PVT LTD Ref No 585353852706 -SBI',
      accountName: 'SBI',
    );

    expect(parsed, isNotNull);
    final pending = PendingTransaction.fromParsed(
      parsed: parsed!,
      sourcePackage: 'com.google.android.apps.messaging',
      accountHint: 'SBI',
      sourceId: 'notification-1',
    );

    expect(pending.amount, 5);
    expect(pending.type, TransactionType.income);
    expect(pending.accountHint, 'SBI');
    expect(pending.reference, '585353852706');
    expect(pending.sourcePackage, 'com.google.android.apps.messaging');
  });

  test('pending transactions survive JSON persistence round trip', () {
    final original = PendingTransaction(
      id: 'notification-2',
      sourcePackage: 'com.example.bank',
      accountHint: 'HDFC',
      amount: 260.18,
      type: TransactionType.expense,
      date: DateTime(2026, 9, 27, 13, 38, 39),
      description: 'PTM*ZOMATO LIMITED',
      paymentMethod: PaymentMethod.creditCard,
      reference: null,
      suggestedCategory: null,
      rawMessage: 'Spent Rs.260.18 at PTM*ZOMATO LIMITED',
    );

    final encoded = pendingTransactionsToJson([original]);
    final restored = pendingTransactionsFromJson(encoded);

    expect(restored, hasLength(1));
    expect(restored.single.id, original.id);
    expect(restored.single.amount, original.amount);
    expect(restored.single.type, original.type);
    expect(restored.single.date, original.date);
    expect(restored.single.description, original.description);
    expect(restored.single.paymentMethod, original.paymentMethod);
    expect(restored.single.rawMessage, original.rawMessage);
  });
}
