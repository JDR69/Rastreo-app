# App Flutter de Rastreo (Android)

Requisitos:
- Flutter 3.24+

## Configurar API

Edita `lib/config.dart` y cambia `apiBase` a la IP del servidor Django en tu red:

```dart
static const String apiBase = 'http://192.168.0.100:8000/api';
```

## Permisos

El `android/app/src/main/AndroidManifest.xml` ya incluye permisos para ubicación, red, WiFi, Internet y servicio en foreground.

## Ejecutar

- Modo debug:
	- Conecta el dispositivo Android.
	- `flutter run`

- Generar APK:
	- `flutter build apk --release`

## Uso

1. Abre la app y pulsa "Iniciar recolección".
2. La app capturará un evento cada ~15s (configurable) y los enviará en lotes de hasta 100.
3. Si no hay red, se guardan localmente hasta 3 horas.
