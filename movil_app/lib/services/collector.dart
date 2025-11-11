import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/local_queue.dart';
import 'carrier.dart';
import '../config.dart';

class DataCollectorService {
  final LocalQueueService _queue = LocalQueueService();
  final Battery _battery = Battery();
  Timer? _timer;

  Future<void> start() async {
    await _queue.init();
    await _ensurePermissions();
    // ignore: avoid_print
    print('[collector] starting timer every \\${AppConfig.intervalSeconds}s');
    _timer = Timer.periodic(Duration(seconds: AppConfig.intervalSeconds), (
      _,
    ) async {
      await collectOnce();
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
  }

  Future<void> collectOnce() async {
    try {
      final pos = await _obtainPosition();
      if (pos == null) {
        // ignore: avoid_print
        print('[collector][warn] posición no disponible (saltando evento)');
        return; // sin posición no guardamos nada
      }
      final batteryLevel = await _battery.batteryLevel; // 0-100
      // Datos de red (simplificado)
      int? cellDbm; // emulador: típicamente null
      String? cellType; // 'wifi' | 'mobile' | 'none'
      try {
        final conn = await Connectivity().checkConnectivity();
        if (conn == ConnectivityResult.wifi) {
          cellType = 'wifi';
        } else if (conn == ConnectivityResult.mobile) {
          cellType = 'mobile';
        } else {
          cellType = 'none';
        }
      } catch (_) {}
      // Obtener operador telefónico (telefonia) vía canal nativo
      String? carrier;
      try {
        carrier = await CarrierService.getCarrierName();
      } catch (_) {}

      final ev = _queue.addSimple(
        latitud: pos.latitude,
        longitud: pos.longitude,
        dbmInternet: cellDbm,
        typeInternet: cellType,
        btteryLevel: batteryLevel.toDouble(),
        telefonia: carrier,
      );
      // Debug log: confirma encolado
      // ignore: avoid_print
      print(
        '[collector] encolado id=${ev.id} lat=${ev.latitud} lng=${ev.longitud} batt=${ev.btteryLevel} type=${cellType ?? 'null'} tel=${carrier ?? 'null'}',
      );
    } catch (e) {
      // Reportar errores puntuales para debug
      // ignore: avoid_print
      print('[collector][error] $e');
    }
  }

  /// Intenta obtener una posición con varias estrategias para evitar Timeout perpetuo.
  Future<Position?> _obtainPosition() async {
    // Si está activado el modo de ubicación simulada, usarla directamente
    if (AppConfig.useSimulatedLocation) {
      // ignore: avoid_print
      print('[collector][debug] usando ubicación simulada');
      return Position(
        latitude: AppConfig.simulatedLatitude,
        longitude: AppConfig.simulatedLongitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    try {
      // 1. Intento directo (medium) con timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // ignore: avoid_print
      print(
        '[collector][debug] Timeout getCurrentPosition, intentando lastKnownPosition',
      );
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
      } catch (e) {
        // ignore: avoid_print
        print('[collector][debug] lastKnownPosition error: $e');
      }
      // 2. Escuchar stream una sola vez (low) con timeout
      try {
        final stream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 0,
          ),
        );
        return await stream.first.timeout(const Duration(seconds: 8));
      } catch (e) {
        // ignore: avoid_print
        print('[collector][debug] stream first error: $e');
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[collector][debug] posición error inmediato: $e');
      return null;
    }
  }

  Future<void> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Intentar abrir ajustes para activar ubicación
      await Geolocator.openLocationSettings();
      // ignore: avoid_print
      print('[collector][perm] servicio de ubicación estaba desactivado');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // ignore: avoid_print
      print('[collector][perm] solicitando permiso ubicación');
    }
    if (permission == LocationPermission.deniedForever) {
      // Solo sugerir abrir ajustes
      await Geolocator.openAppSettings();
      // ignore: avoid_print
      print('[collector][perm] permiso denegado para siempre, abrir ajustes');
    }
    // ignore: avoid_print
    print(
      '[collector][perm] estado permiso: $permission servicio: $serviceEnabled',
    );
  }

  int get queuedEvents => _queue.length;
}
