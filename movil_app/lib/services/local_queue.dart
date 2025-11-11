import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
// No config needed here

/// Cola local basada en archivo JSON para simplicidad (evita necesidad de base de datos al inicio).
class LocalQueueService {
  static final LocalQueueService _instance = LocalQueueService._internal();
  factory LocalQueueService() => _instance;
  LocalQueueService._internal();

  final _uuid = const Uuid();
  File? _file;
  List<EventModel> _events = [];
  // No device id required in simplified schema

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/events_queue.json');
    if (await _file!.exists()) {
      try {
        final content = await _file!.readAsString();
        final data = jsonDecode(content);
        if (data is List) {
          _events = data.map((e) => EventModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }
    _purgeOld();
  }

  void _persist() {
    if (_file == null) return;
    final data = _events.map((e) => e.toJson()).toList();
    _file!.writeAsString(jsonEncode(data), flush: true);
  }

  void _purgeOld() {
    // Ya no usamos ts en el modelo simplificado, mantener por compatibilidad antigua
    _persist();
  }

  EventModel addSimple({
    required double latitud,
    required double longitud,
    required int? dbmInternet,
    required String? typeInternet,
    required double btteryLevel,
    String? telefonia,
  }) {
    final ev = EventModel(
      id: _uuid.v4(),
      latitud: latitud,
      longitud: longitud,
      dbmInternet: dbmInternet,
      typeInternet: typeInternet,
      btteryLevel: btteryLevel,
      telefonia: telefonia,
    );
    _events.add(ev);
    _purgeOld();
    _persist();
    return ev;
  }

  List<EventModel> peekBatch(int max) {
    return _events.take(max).toList();
  }

  void removeBatch(List<EventModel> batch) {
    final ids = batch.map((e) => e.id).toSet();
    _events.removeWhere((e) => ids.contains(e.id));
    _persist();
  }

  int get length => _events.length;
}
