import 'package:flutter/services.dart';

class CapturedNotification {
  final String packageName;
  final String title;
  final String text;
  final DateTime receivedAt;

  const CapturedNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.receivedAt,
  });

  String get message =>
      [title, text].where((value) => value.trim().isNotEmpty).join(' - ');

  factory CapturedNotification.fromMap(Map<Object?, Object?> map) {
    return CapturedNotification(
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['receivedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class NotificationCaptureService {
  static const _channel = MethodChannel('paisa/notification_capture');

  Future<bool> isAccessEnabled() async {
    return await _channel.invokeMethod<bool>('isAccessEnabled') ?? false;
  }

  Future<void> openAccessSettings() async {
    await _channel.invokeMethod<void>('openAccessSettings');
  }

  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setCaptureEnabled', enabled);
  }

  Future<List<CapturedNotification>> readCaptured() async {
    final result = await _channel.invokeListMethod<Object?>('readCaptured');
    return (result ?? [])
        .whereType<Map<Object?, Object?>>()
        .map(CapturedNotification.fromMap)
        .toList();
  }

  Future<void> clearCaptured() async {
    await _channel.invokeMethod<void>('clearCaptured');
  }
}
