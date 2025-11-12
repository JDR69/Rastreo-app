class AppConfig {
  // TODO: Cambia la IP al servidor Django en tu red local
  //static const String apiBase = 'http://192.168.0.100:8000/api';
  //static const String apiBase = 'http://10.0.2.2:8000/api';
  static const String apiBase = 'https://rastreo-app.onrender.com/api';
  // Intervalo en segundos entre eventos
  static const int intervalSeconds = 5; // exacto cada 5s

  // Tamaño del lote a enviar
  static const int batchSize = 100;

  // Retención máxima en milisegundos (3 horas)
  static const int retentionMs = 3 * 60 * 60 * 1000;

  // Modo de prueba: usar ubicación simulada (útil para emulador con problemas de GPS)
  static const bool useSimulatedLocation = false;

  // Ubicación simulada (Santa Cruz, Bolivia como ejemplo)
  static const double simulatedLatitude = -17.783333;
  static const double simulatedLongitude = -63.182222;
}
