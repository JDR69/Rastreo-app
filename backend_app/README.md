# Backend Django + MongoDB (ingesta de eventos)

## Configuración

1. Requisitos:
   - Python 3.10+
   - MongoDB local (por defecto: `mongodb://localhost:27017`)

2. Instalar dependencias:

```bash
pip install -r requirements.txt
```

3. Variables de entorno (opcional):

- `MONGO_URI` (default `mongodb://localhost:27017`)
- `MONGO_DB` (default `rastreo_db`)

4. Ejecutar servidor:

```bash
python manage.py runserver 0.0.0.0:8000
```

## Endpoint

POST `/api/events/batch`

Body: JSON array de eventos, cada uno con:

```json
{
  "deviceId": "string",
  "ts": 1731240000000,
  "location": {"lat": -17.0, "lng": -63.0, "accuracy": 10.0, "altitude": 400.2, "speed": 0.1, "heading": 90.0},
  "network": {"cellSignalDbm": -90, "cellType": "4G", "wifiRssi": -60, "wifiSsid": "MiWifi"},
  "battery": {"level": 0.84, "isCharging": false}
}
```

Respuesta:

```json
{"inserted": 1, "rejected": 0}
```
