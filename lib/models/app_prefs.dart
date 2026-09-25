import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lightweight JSON-file-based preferences store.
/// Loaded AFTER the first frame (safe, no platform-channel deadlock).
class AppPrefs {
  static AppPrefs? _instance;
  static AppPrefs get instance => _instance ??= AppPrefs._();
  AppPrefs._();

  Map<String, dynamic> _data = {};
  File? _file;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/paisa_prefs.json');
    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        _data = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        _data = {};
      }
    }
  }

  Future<void> _save() async {
    await _file?.writeAsString(json.encode(_data));
  }

  // ─── Spending limit ───────────────────────────────────────────
  double? get spendingLimit {
    final v = _data['spending_limit'];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  Future<void> setSpendingLimit(double? limit) async {
    if (limit == null) {
      _data.remove('spending_limit');
    } else {
      _data['spending_limit'] = limit;
    }
    await _save();
  }

  // ─── PIN ─────────────────────────────────────────────────────
  /// Stored as a simple 4-digit string (no hashing needed for
  /// a personal offline app — hashing adds complexity with no
  /// real adversary model here).
  String? get pin => _data['pin'] as String?;

  Future<void> setPin(String? pin) async {
    if (pin == null) {
      _data.remove('pin');
    } else {
      _data['pin'] = pin;
    }
    await _save();
  }

  bool get hasPin =>
      _data.containsKey('pin') && (_data['pin'] as String?)?.isNotEmpty == true;

  bool verifyPin(String input) => input == pin;

  // ─── Generic ─────────────────────────────────────────────────
  T? get<T>(String key) => _data[key] as T?;

  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
    await _save();
  }

  Future<void> remove(String key) async {
    _data.remove(key);
    await _save();
  }

  // ─── Theme mode ─────────────────────────────────────────────
  /// 'dark' | 'light' | 'system'
  String get themeMode => (_data['theme_mode'] as String?) ?? 'dark';

  Future<void> setThemeMode(String mode) async {
    _data['theme_mode'] = mode;
    await _save();
  }

  // ─── Accounts (JSON-encoded list) ───────────────────────────
  String get accountsJson => (_data['accounts'] as String?) ?? '[]';

  Future<void> setAccountsJson(String raw) async {
    _data['accounts'] = raw;
    await _save();
  }

  String get transfersJson => (_data['transfers'] as String?) ?? '[]';

  Future<void> setTransfersJson(String raw) async {
    _data['transfers'] = raw;
    await _save();
  }

  // ─── Notifications enabled ───────────────────────────────────
  bool get notificationsEnabled =>
      (_data['notifications_enabled'] as bool?) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    _data['notifications_enabled'] = value;
    await _save();
  }

  String get currencySymbol => (_data['currency_symbol'] as String?) ?? '₹';

  Future<void> setCurrencySymbol(String value) async {
    _data['currency_symbol'] = value;
    await _save();
  }

  bool get currencyPrefix => (_data['currency_prefix'] as bool?) ?? true;

  Future<void> setCurrencyPrefix(bool value) async {
    _data['currency_prefix'] = value;
    await _save();
  }

  int get currencyDecimals => (_data['currency_decimals'] as int?) ?? 2;

  Future<void> setCurrencyDecimals(int value) async {
    _data['currency_decimals'] = value.clamp(0, 2).toInt();
    await _save();
  }

  Map<String, dynamic> exportData() => Map<String, dynamic>.from(_data);

  Future<void> replaceData(Map<String, dynamic> data) async {
    _data = Map<String, dynamic>.from(data);
    await _save();
  }
}
