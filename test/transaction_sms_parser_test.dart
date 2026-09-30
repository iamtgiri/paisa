import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/models/transaction.dart';
import 'package:paisa/utils/transaction_sms_parser.dart';

void main() {
  test('parses SBI credit from Google', () {
    final result = TransactionSmsParser.parse(
      'Dear SBI User, your A/c X2425-credited by Rs.5 on 27Sep26 transfer from '
      'GOOGLE INDIA DIGITAL SERVICES PVT LTD Ref No 585353852706 -SBI',
      accountName: 'SBI',
    );

    expect(result, isNotNull);
    expect(result!.amount, 5);
    expect(result.type, TransactionType.income);
    expect(result.description, 'GOOGLE INDIA DIGITAL SERVICES PVT LTD');
    expect(result.date, DateTime(2026, 9, 27));
    expect(result.reference, '585353852706');
  });

  test('parses ICICI credit card UPI expense', () {
    final result = TransactionSmsParser.parse(
      'ICICI Bank Credit Card XX4020 debited for INR 153.00 on 27-Sep-26 '
      'for UPI-663640644936-Meesho. To dispute call 18001080',
      accountName: 'ICICI-CC',
    );

    expect(result, isNotNull);
    expect(result!.amount, 153);
    expect(result.type, TransactionType.expense);
    expect(result.description, 'Meesho');
    expect(result.paymentMethod, PaymentMethod.upi);
    expect(result.date, DateTime(2026, 9, 27));
  });

  test('parses SBI and FINO account credits', () {
    final sbi = TransactionSmsParser.parse(
      'Dear SBI User, your A/c X2425-credited by Rs.20000 on 30Jul26 '
      'transfer from TANMOY GIRI Ref No 335325642714 -SBI',
      accountName: 'SBI',
    );
    final fino = TransactionSmsParser.parse(
      'Dear Customer, your account XXXXXXX7918 is credited with Rs.270.00 '
      'on 22/09/2026. UPI Ref. No.387669235387.- Fino',
      accountName: 'FINO',
    );

    expect(sbi, isNotNull);
    expect(sbi!.amount, 20000);
    expect(sbi.type, TransactionType.income);
    expect(sbi.description, 'TANMOY GIRI');
    expect(sbi.date, DateTime(2026, 7, 30));
    expect(sbi.reference, '335325642714');
    expect(fino, isNotNull);
    expect(fino!.amount, 270);
    expect(fino.type, TransactionType.income);
    expect(fino.paymentMethod, PaymentMethod.upi);
    expect(fino.date, DateTime(2026, 9, 22));
    expect(fino.reference, '387669235387');
  });

  test('parses ICICI and FINO debit formats', () {
    final icici = TransactionSmsParser.parse(
      'ICICI Bank Credit Card XX4020 debited for INR 495.00 on 26-Aug-26 '
      'for UPI-623868641560-INDIGO.',
      accountName: 'ICICI-CC',
    );
    final fino = TransactionSmsParser.parse(
      'A/c XX7918 debited for Rs 33.00 on 18-Sep-26, AJAY KUMAR credited. '
      'Balance 1498.47',
      accountName: 'FINO',
    );

    expect(icici, isNotNull);
    expect(icici!.amount, 495);
    expect(icici.description, 'INDIGO');
    expect(icici.date, DateTime(2026, 8, 26));
    expect(fino, isNotNull);
    expect(fino!.amount, 33);
    expect(fino.type, TransactionType.expense);
    expect(fino.description, 'AJAY KUMAR');
    expect(fino.date, DateTime(2026, 9, 18));
  });

  test('parses HDFC card merchant and timestamp', () {
    final result = TransactionSmsParser.parse(
      'Spent Rs.260.18 On HDFC Bank Card 5030 At PTM*ZOMATO LIMITED '
      'On 2026-09-27:13:38:39.Not You?',
      accountName: 'HDFC-CC',
    );

    expect(result, isNotNull);
    expect(result!.amount, 260.18);
    expect(result.type, TransactionType.expense);
    expect(result.description, 'PTM*ZOMATO LIMITED');
    expect(result.paymentMethod, PaymentMethod.creditCard);
    expect(result.date, DateTime(2026, 9, 27, 13, 38, 39));
  });

  test('parses HDFC transfer to a person', () {
    final result = TransactionSmsParser.parse(
      'Sent Rs.10.00 From HDFC Bank A/C *2192 To RAULI On 22/09/26 '
      'Ref 663181258342 Not You?',
      accountName: 'HDFC',
    );

    expect(result, isNotNull);
    expect(result!.amount, 10);
    expect(result.type, TransactionType.expense);
    expect(result.description, 'RAULI');
    expect(result.date, DateTime(2026, 9, 22));
    expect(result.reference, '663181258342');
  });

  test('parses ATM withdrawal as cash expense', () {
    final result = TransactionSmsParser.parse(
      'Dear SBI Customer, Rs.6000 withdrawn at SBI ATM S1BP006866305 from '
      'A/cX2415 on 05Sep26 Transaction Number 926. Available Balance Rs.0.00.',
      accountName: 'SBI',
    );

    expect(result, isNotNull);
    expect(result!.amount, 6000);
    expect(result.type, TransactionType.expense);
    expect(result.paymentMethod, PaymentMethod.cash);
    expect(result.suggestedCategory, 'Cash Withdrawal');
    expect(result.description, 'SBI ATM S1BP006866305');
    expect(result.date, DateTime(2026, 9, 5));
    expect(result.reference, '926');
  });

  test('ignores OTP and non-transaction messages', () {
    expect(
      TransactionSmsParser.parse(
        'Your OTP for login is 123456. Do not share this code.',
        accountName: 'SBI',
      ),
      isNull,
    );
    expect(
      TransactionSmsParser.parse(
        'Your SBI service request has been registered successfully.',
        accountName: 'SBI',
      ),
      isNull,
    );
  });
}
