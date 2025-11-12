import 'package:flutter/services.dart';

class SignalService {
  static const MethodChannel _channel = MethodChannel('app.signal');

  static Future<int?> getSignalDbm() async {
    try {
      final dbm = await _channel.invokeMethod<int>('getSignalDbm');
      return dbm;
    } catch (_) {
      return null;
    }
  }
}
