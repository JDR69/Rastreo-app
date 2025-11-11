import 'dart:convert';
import 'package:dio/dio.dart';
import '../config.dart';
import 'local_queue.dart';

class SyncService {
  final Dio _dio = Dio()
    ..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  final LocalQueueService _queue = LocalQueueService();

  Future<void> trySync() async {
    final batch = _queue.peekBatch(AppConfig.batchSize);
    // ignore: avoid_print
    print('[sync] batch-size=${batch.length} queue=${_queue.length}');
    if (batch.isEmpty) return;
    final payload = batch
        .map((e) => e.toJson())
        .toList(); // lista de objetos simples
    try {
      final resp = await _dio.post(
        '${AppConfig.apiBase}/events/batch',
        data: jsonEncode(payload),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (resp.statusCode == 200) {
        final inserted = resp.data['inserted'] ?? 0;
        // ignore: avoid_print
        print('[sync] server-inserted=$inserted');
        if (inserted > 0) {
          _queue.removeBatch(batch.take(inserted).toList());
        }
      }
    } catch (e) {
      // Dejar para reintento posterior
      // ignore: avoid_print
      print('[sync][error] $e');
    }
  }
}
