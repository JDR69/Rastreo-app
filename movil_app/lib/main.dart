import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'services/collector.dart';
import 'services/local_queue.dart';
import 'services/sync_service.dart';
import 'config.dart';

import 'background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuración del servicio se realizará al iniciar desde la UI
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 58, 158, 183),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const MyHomePage(title: 'Rastreo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _collector = DataCollectorService();
  final _syncService = SyncService();
  String? _deviceId;
  Timer? _syncTimer;
  int _queued = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    if (kIsWeb) {
      _deviceId = 'web';
    } else {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        _deviceId = info.id;
      } catch (_) {
        _deviceId = 'unknown-device';
      }
    }
    setState(() {});
  }

  Future<void> _start() async {
    if (kIsWeb) {
      // En Web no inicializamos cola/collector: app enfocada en Android
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta app está diseñada para Android. Usa un emulador o dispositivo Android.',
          ),
        ),
      );
      return;
    }
    await LocalQueueService().init();
    // Solicitar permisos usando el collector y detener su temporizador inmediato
    await _collector.start();
    await _collector.stop();
    // Primera recolección inmediata para tener datos antes del primer tick
    await _collector.collectOnce();
    await _syncService.trySync();
    // Iniciar servicio en segundo plano (recolección y sync cada AppConfig.intervalSeconds)
    await startBackgroundService();
    // Pequeño timer para refrescar indicadores en UI
    _syncTimer = Timer.periodic(Duration(seconds: AppConfig.intervalSeconds), (
      _,
    ) async {
      setState(() {
        _queued = LocalQueueService().length;
      });
    });
    setState(() {
      _running = true;
      _queued = LocalQueueService().length;
    });
  }

  Future<void> _stop() async {
    await stopBackgroundService();
    _syncTimer?.cancel();
    setState(() {
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hola Bicho!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Modo Web: funciones deshabilitadas. Ejecuta en Android.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            Text('DeviceId: ${_deviceId ?? '-'}'),
            const SizedBox(height: 8),
            Text('Cola local: $_queued eventos'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: kIsWeb
                  ? null
                  : () async {
                      if (_running) {
                        await _stop();
                      } else {
                        await _start();
                      }
                    },
              icon: Icon(_running ? Icons.stop : Icons.play_arrow),
              label: Text(
                _running ? 'Detener recolección' : 'Recolectar datos',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _running ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
