import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account.dart';
import '../models/transaction.dart';

class AppUtils {
  // ─── Number formatting ──────────────────────────────────────
  static String _currencySymbol = '₹';
  static bool _currencyPrefix = true;
  static int _currencyDecimals = 2;

  static void configureCurrency({
    required String symbol,
    required bool prefix,
    required int decimals,
  }) {
    _currencySymbol = symbol;
    _currencyPrefix = prefix;
    _currencyDecimals = decimals.clamp(0, 2).toInt();
  }

  static String formatAmount(double amount,
      {bool compact = false, String? symbol}) {
    final cur = symbol ?? _currencySymbol;
    final decimals = compact ? 0 : _currencyDecimals;
    final pattern = decimals == 0 ? '#,##,##0' : '#,##,##0.00';
    final value = NumberFormat(pattern, 'en_IN').format(amount);
    return _currencyPrefix ? '$cur$value' : '$value $cur';
  }

  static String formatAmountSigned(double amount, TransactionType type,
      {String? symbol}) {
    final prefix = type == TransactionType.income ? '+' : '-';
    return '$prefix${formatAmount(amount, symbol: symbol)}';
  }

  // ─── Date formatting ─────────────────────────────────────────
  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    if (d.year == now.year) return DateFormat('d MMM').format(dt);
    return DateFormat('d MMM y').format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('d MMM y, h:mm a').format(dt);
  }

  static String formatMonthYear(int year, int month) {
    return DateFormat('MMMM y').format(DateTime(year, month));
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('d MMM').format(dt);
  }

  // ─── Icon lookup map ─────────────────────────────────────────
  // Maps every hex codepoint string used anywhere in the app to a
  // concrete Icons.* constant. All values here are compile-time
  // constants — the tree shaker can see them statically.
  // NEVER call IconData(int.parse(...)) in release mode.
  static const Map<String, IconData> _iconMap = {
    // Used in category seeds & picker
    'e25a': Icons.restaurant,
    'e1fc': Icons.shopping_basket,
    'e531': Icons.directions_car,
    'e530': Icons.directions_bus,
    'e145': Icons.flight,
    'e570': Icons.train,
    'e8cc': Icons.shopping_bag,
    'e40b': Icons.movie,
    'e80c': Icons.school,
    'e548': Icons.local_hospital,
    'e1db': Icons.power,
    'e88a': Icons.home,
    'e31a': Icons.spa,
    'e227': Icons.account_balance_wallet,
    'e8f9': Icons.work,
    'e0af': Icons.business_center,
    'e8dc': Icons.trending_up,
    'e8b1': Icons.reply,
    'e8b8': Icons.more_horiz,
    'e838': Icons.star,
    'e87e': Icons.favorite_border,
    'e87d': Icons.favorite,
    'efef': Icons.coffee,
    'ea2a': Icons.sports,
    'e91d': Icons.pets,
    'e0cd': Icons.phone_android,
    'e8f6': Icons.card_giftcard,
    'e405': Icons.music_note,
    'e865': Icons.menu_book,
    // Extra used in categories
    'e546': Icons.local_gas_station,
    'e558': Icons.local_taxi,
    'e798': Icons.water_drop,
    'e63e': Icons.wifi,
    'e870': Icons.credit_card,
    'e2d6': Icons.account_balance,
    'e54f': Icons.local_pharmacy,
    'ea26': Icons.fitness_center,
    'e549': Icons.hotel,
    // Account screen presets
    'e0d6': Icons.payments,
    // Alcohol / bar
    'eb3c': Icons.local_bar,
    // Fallback
    'e8b8_': Icons.more_horiz,
  };

  /// Returns the IconData for a stored hex codepoint string.
  /// Falls back to Icons.category for any unknown key.
  /// Release-safe — no runtime IconData construction.
  static IconData iconFromHex(String hex) {
    return _iconMap[hex] ?? Icons.category;
  }

  // ─── Payment method ──────────────────────────────────────────
  static String paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static IconData paymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.upi:
        return Icons.phone_android;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.creditCard:
        return Icons.credit_card_outlined;
      case PaymentMethod.netBanking:
        return Icons.account_balance;
      case PaymentMethod.other:
        return Icons.payment;
    }
  }

  static String transactionPaymentLabel(
      Transaction transaction, List<Account> accounts) {
    final account = _accountById(accounts, transaction.paymentAccountId);
    if (account != null) return account.name;
    return paymentMethodLabel(transaction.paymentMethod);
  }

  static IconData transactionPaymentIcon(
      Transaction transaction, List<Account> accounts) {
    final account = _accountById(accounts, transaction.paymentAccountId);
    if (account != null) return iconFromHex(account.icon);
    return paymentMethodIcon(transaction.paymentMethod);
  }

  static Account? _accountById(List<Account> accounts, String? id) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  // ─── Color helpers ───────────────────────────────────────────
  static Color colorFromValue(int value) => Color(value);

  static List<Color> get chartColors => const [
        Color(0xFF00BFA5),
        Color(0xFFFF6B6B),
        Color(0xFF6C63FF),
        Color(0xFFFFB74D),
        Color(0xFF4FC3F7),
        Color(0xFFAED581),
        Color(0xFFFF8A65),
        Color(0xFFE57373),
        Color(0xFF81C784),
        Color(0xFF64B5F6),
        Color(0xFFBA68C8),
        Color(0xFF4DD0E1),
      ];

  // ─── Category icon picker list ────────────────────────────────
  // Stores (label, hex key) — the hex key is looked up via iconFromHex()
  // which returns a pre-declared Icons.* constant (tree-shaker safe).
  static const List<(String, String)> categoryIcons = [
    ('Restaurant', 'e25a'),
    ('Basket', 'e1fc'),
    ('Car', 'e531'),
    ('Bus', 'e530'),
    ('Plane', 'e145'),
    ('Train', 'e570'),
    ('Shopping', 'e8cc'),
    ('Movie', 'e40b'),
    ('School', 'e80c'),
    ('Hospital', 'e548'),
    ('Power', 'e1db'),
    ('Home', 'e88a'),
    ('Spa', 'e31a'),
    ('Wallet', 'e227'),
    ('Work', 'e8f9'),
    ('Business', 'e0af'),
    ('Trending Up', 'e8dc'),
    ('Reply', 'e8b1'),
    ('More', 'e8b8'),
    ('Star', 'e838'),
    ('Heart', 'e87d'),
    ('Coffee', 'efef'),
    ('Sports', 'ea26'),
    ('Pets', 'e91d'),
    ('Phone', 'e0cd'),
    ('Gift', 'e8f6'),
    ('Music', 'e405'),
    ('Book', 'e865'),
    ('Gas Station', 'e546'),
    ('Taxi', 'e558'),
    ('Water', 'e798'),
    ('WiFi', 'e63e'),
    ('Card', 'e870'),
    ('Bank', 'e2d6'),
    ('Pharmacy', 'e54f'),
    ('Fitness', 'ea26'),
    ('Hotel', 'e549'),
    ('Payments', 'e0d6'),
    ('Favorite', 'e87e'),
  ];

  static const List<(String, int)> categoryColors = [
    ('Red', 0xFFE53935),
    ('Pink', 0xFFD81B60),
    ('Purple', 0xFF8E24AA),
    ('Deep Purple', 0xFF5E35B1),
    ('Indigo', 0xFF3949AB),
    ('Blue', 0xFF1E88E5),
    ('Light Blue', 0xFF039BE5),
    ('Cyan', 0xFF00ACC1),
    ('Teal', 0xFF00897B),
    ('Green', 0xFF43A047),
    ('Light Green', 0xFF7CB342),
    ('Yellow', 0xFFF9A825),
    ('Orange', 0xFFFB8C00),
    ('Deep Orange', 0xFFE64A19),
    ('Brown', 0xFF6D4C41),
    ('Grey', 0xFF757575),
    ('Blue Grey', 0xFF546E7A),
    ('Coral', 0xFFFF6B6B),
  ];
}
