import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'services/collector.dart';
import 'services/sync_service.dart';
import 'config.dart';
import 'package:flutter/widgets.dart';
import 'services/local_queue.dart';

bool _configured = false;

Future<void> _configureIfNeeded() async {
  if (_configured) return;
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // iniciar explícitamente desde la UI
      isForegroundMode: true,
      notificationChannelId: 'rastreo_channel',
      initialNotificationTitle: 'Rastreo activo',
      initialNotificationContent: 'Recolectando datos en segundo plano',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
  _configured = true;
}

Future<void> startBackgroundService() async {
  await _configureIfNeeded();
  await FlutterBackgroundService().startService();
}

Future<void> stopBackgroundService() async {
  // El plugin actual no expone stopService; podemos enviar un evento para que
  // la lógica interna deje de ejecutar o dejarlo como no-op.
  // Aquí simplemente enviamos una señal que podríamos manejar en onStart si se extiende.
  try {
    FlutterBackgroundService().invoke('stop');
  } catch (_) {}
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  // Asegurar que los plugins estén registrados en el isolate de background
  WidgetsFlutterBinding.ensureInitialized();
  // DartPluginRegistrant.ensureInitialized(); // opcional según versión
  final collector = DataCollectorService();
  final sync = SyncService();
  final queue = LocalQueueService();
  // Poner en foreground explícitamente
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }
  Timer? t;
  t = Timer.periodic(Duration(seconds: AppConfig.intervalSeconds), (
    timer,
  ) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) return;
    }
    try {
      // ignore: avoid_print
      print('[bg] tick -> collect + sync');
      await collector.collectOnce();
      await sync.trySync();
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Rastreo activo',
          content: 'Cola: ${queue.length} eventos',
        );
      }
    } catch (_) {
      // swallow errors to avoid crashing the service
    }
  });

  // Permitir detener el servicio desde la UI
  service.on('stop').listen((event) async {
    try {
      // ignore: avoid_print
      print('[bg] stop signal received');
      t?.cancel();
      if (service is AndroidServiceInstance) {
        service.stopSelf();
      }
    } catch (_) {}
  });
}
