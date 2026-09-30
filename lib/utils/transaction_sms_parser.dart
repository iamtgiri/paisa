import '../models/transaction.dart';

class ParsedNotificationTransaction {
  final String accountName;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String description;
  final PaymentMethod paymentMethod;
  final String? reference;
  final String? suggestedCategory;
  final double confidence;
  final String rawMessage;

  const ParsedNotificationTransaction({
    required this.accountName,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
    required this.paymentMethod,
    required this.reference,
    required this.suggestedCategory,
    required this.confidence,
    required this.rawMessage,
  });

  bool get isExpense => type == TransactionType.expense;
}

class TransactionSmsParser {
  static final _amountPattern = RegExp(
    r'\b(?:rs\.?|inr)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _referencePattern = RegExp(
    r'\b(?:ref(?:erence)?(?:\s+no\.?)?|upi\s+ref\.?'
    r'|transaction\s+(?:number|no\.?)\s*)[:.]?\s*([A-Za-z0-9-]+)',
    caseSensitive: false,
  );

  static ParsedNotificationTransaction? parse(
    String message, {
    required String accountName,
    DateTime? now,
  }) {
    final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return null;

    final lower = normalized.toLowerCase();
    if (_isNonFinancialMessage(lower)) return null;

    final type = _transactionType(lower);
    if (type == null) return null;

    final amountMatch = _amountPattern.firstMatch(normalized);
    if (amountMatch == null) return null;
    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    final date = _parseDate(normalized, now ?? DateTime.now());
    if (date == null) return null;

    final isAtm = lower.contains('withdrawn') || lower.contains('atm');
    final paymentMethod = _paymentMethod(lower, accountName, isAtm);
    final description = _description(normalized, type, isAtm);
    final reference = _referencePattern.firstMatch(normalized)?.group(1);

    return ParsedNotificationTransaction(
      accountName: accountName,
      amount: amount,
      type: type,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      suggestedCategory: isAtm ? 'Cash Withdrawal' : null,
      confidence: _confidence(normalized, type, date, reference),
      rawMessage: message,
    );
  }

  static bool _isNonFinancialMessage(String lower) {
    if (RegExp(r'\b(?:otp|one[- ]time password|verification code|login code)\b')
        .hasMatch(lower)) {
      return true;
    }
    return !RegExp(r'\b(?:credited|debited|spent|sent|withdrawn)\b')
        .hasMatch(lower);
  }

  static TransactionType? _transactionType(String lower) {
    if (RegExp(r'\bcredited\b').hasMatch(lower)) {
      return TransactionType.income;
    }
    if (RegExp(r'\b(?:debited|spent|sent|withdrawn)\b').hasMatch(lower)) {
      return TransactionType.expense;
    }
    return null;
  }

  static PaymentMethod _paymentMethod(
      String lower, String accountName, bool isAtm) {
    if (isAtm) return PaymentMethod.cash;
    if (lower.contains('upi')) return PaymentMethod.upi;
    if (accountName.toLowerCase().contains('cc') ||
        lower.contains('credit card')) {
      return PaymentMethod.creditCard;
    }
    return PaymentMethod.other;
  }

  static String _description(String message, TransactionType type, bool isAtm) {
    if (isAtm) {
      final match =
          RegExp(r'withdrawn\s+at\s+(.+?)\s+from\s+', caseSensitive: false)
              .firstMatch(message);
      return match?.group(1)?.trim() ?? 'ATM withdrawal';
    }

    final transfer =
        RegExp(r'transfer\s+from\s+(.+?)\s+ref\s+no', caseSensitive: false)
            .firstMatch(message);
    if (transfer != null) return transfer.group(1)!.trim();

    final cardMerchant = RegExp(
            r'\bfor\s+upi-\d+-(.+?)(?:\.|\s+to\s+dispute|$)',
            caseSensitive: false)
        .firstMatch(message);
    if (cardMerchant != null) return cardMerchant.group(1)!.trim();

    final spentAt = RegExp(r'\bat\s+(.+?)\s+on\s+\d{4}-', caseSensitive: false)
        .firstMatch(message);
    if (spentAt != null) return spentAt.group(1)!.trim();

    final sentTo = RegExp(r'\bto\s+(.+?)\s+on\s+', caseSensitive: false)
        .firstMatch(message);
    if (sentTo != null) return sentTo.group(1)!.trim();

    final creditedTo = RegExp(r'\b,\s*(.+?)\s+credited\b', caseSensitive: false)
        .firstMatch(message);
    if (creditedTo != null) return creditedTo.group(1)!.trim();

    return type == TransactionType.income ? 'Bank credit' : 'Bank transaction';
  }

  static DateTime? _parseDate(String message, DateTime now) {
    final iso = RegExp(
      r'\b(\d{4})-(\d{1,2})-(\d{1,2})(?:[: ](\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(message);
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
        int.tryParse(iso.group(4) ?? '') ?? 0,
        int.tryParse(iso.group(5) ?? '') ?? 0,
        int.tryParse(iso.group(6) ?? '') ?? 0,
      );
    }

    final monthName = RegExp(
      r'\b(\d{1,2})[- ]([A-Za-z]{3})[- ](\d{2,4})\b',
    ).firstMatch(message);
    if (monthName != null) {
      final month = _monthNumber(monthName.group(2)!);
      if (month == null) return null;
      return _dateWithYear(
        int.parse(monthName.group(1)!),
        month,
        int.parse(monthName.group(3)!),
      );
    }

    final compactMonth =
        RegExp(r'\b(\d{1,2})([A-Za-z]{3})(\d{2,4})\b').firstMatch(message);
    if (compactMonth != null) {
      final month = _monthNumber(compactMonth.group(2)!);
      if (month == null) return null;
      return _dateWithYear(
        int.parse(compactMonth.group(1)!),
        month,
        int.parse(compactMonth.group(3)!),
      );
    }

    final slash =
        RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{2,4})\b').firstMatch(message);
    if (slash != null) {
      return _dateWithYear(
        int.parse(slash.group(1)!),
        int.parse(slash.group(2)!),
        int.parse(slash.group(3)!),
      );
    }

    return null;
  }

  static DateTime _dateWithYear(int day, int month, int rawYear) {
    final year = rawYear < 100 ? 2000 + rawYear : rawYear;
    return DateTime(year, month, day);
  }

  static int? _monthNumber(String value) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return months[value.toLowerCase()];
  }

  static double _confidence(
      String message, TransactionType type, DateTime? date, String? reference) {
    var score = 0.70;
    if (date != null) score += 0.10;
    if (reference != null) score += 0.10;
    if (message.toLowerCase().contains('upi')) score += 0.05;
    if (type == TransactionType.income ||
        message.toLowerCase().contains('card')) {
      score += 0.05;
    }
    return score.clamp(0.0, 1.0).toDouble();
  }
}
