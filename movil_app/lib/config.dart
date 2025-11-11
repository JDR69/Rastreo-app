class AppConfig {
  // TODO: Cambia la IP al servidor Django en tu red local
  //static const String apiBase = 'http://192.168.0.100:8000/api';
  static const String apiBase = 'http://10.0.2.2:8000/api';

  // Intervalo en segundos entre eventos
  static const int intervalSeconds = 10; // exacto cada 10s

  // Tamaño del lote a enviar
  static const int batchSize = 100;

  // Retención máxima en milisegundos (3 horas)
  static const int retentionMs = 3 * 60 * 60 * 1000;
}
