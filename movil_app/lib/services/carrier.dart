import 'package:flutter/services.dart';

class CarrierService {
  static const MethodChannel _channel = MethodChannel('app.telefonia');

  static Future<String?> getCarrierName() async {
    try {
      final name = await _channel.invokeMethod<String>('getCarrierName');
      return name;
    } catch (_) {
      return null;
    }
  }
}
