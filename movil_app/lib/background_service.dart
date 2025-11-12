import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'services/collector.dart';
import 'services/sync_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'rastreo_channel',
      initialNotificationTitle: 'Rastreo activo',
      initialNotificationContent: 'Recolectando datos en segundo plano',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
  await service.startService();
}

void onStart(ServiceInstance service) {
  final collector = DataCollectorService();
  final sync = SyncService();
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) return;
    }
    await collector.collectOnce();
    await sync.trySync();
  });
}
