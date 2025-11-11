class EventModel {
  final String id; // UUID del evento
  final double latitud;
  final double longitud;
  final int? dbmInternet; // puede ser null
  final String? typeInternet;
  final double btteryLevel; // 0-100
  final String? telefonia; // Entel | Tigo | Viva | null

  EventModel({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.dbmInternet,
    required this.typeInternet,
    required this.btteryLevel,
    required this.telefonia,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitud': latitud,
    'longitud': longitud,
    'DbmInternet': dbmInternet,
    'TypeInternet': typeInternet,
    'BtteryLevel': btteryLevel,
    'Telefonia': telefonia,
  };

  static EventModel fromJson(Map<String, dynamic> j) => EventModel(
    id: j['id'],
    latitud: (j['latitud'] as num).toDouble(),
    longitud: (j['longitud'] as num).toDouble(),
    dbmInternet: j['DbmInternet'] as int?,
    typeInternet: j['TypeInternet'] as String?,
    btteryLevel: (j['BtteryLevel'] as num).toDouble(),
    telefonia: j['Telefonia'] as String?,
  );
}
