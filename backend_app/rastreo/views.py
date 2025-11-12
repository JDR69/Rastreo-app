import json
from typing import List, Dict, Any
from django.http import JsonResponse, HttpRequest
from django.views.decorators.csrf import csrf_exempt
from pymongo import MongoClient
import os

_mongo_client = None

def _get_collection():
	global _mongo_client
	if _mongo_client is None:
		mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017")
		_mongo_client = MongoClient(mongo_uri, serverSelectionTimeoutMS=3000)
	db_name = os.getenv("MONGO_DB", "rastreo_db")
	collection_name = os.getenv("MONGO_COLLECTION", "Telefonia")
	collection = _mongo_client[db_name][collection_name]
	return collection

# Nuevo esquema mínimo solicitado
# Campos: id, latitud, longitud, DbmInternet, TypeInternet, BtteryLevel, Telefonia(opcional)
REQUIRED_FIELDS = ["id", "latitud", "longitud", "BtteryLevel"]

def _validate_event(e: Dict[str, Any]) -> bool:
	for f in REQUIRED_FIELDS:
		if f not in e:
			return False
	# Validar tipos básicos
	try:
		float(e["latitud"])
		float(e["longitud"])
		float(e["BtteryLevel"])  # puede venir 0-100
		str(e["id"])
	except Exception:
		return False
	return True

def _normalize_event(e: Dict[str, Any]) -> Dict[str, Any]:
	# Limitar solo a los campos requeridos por el usuario
	return {
		"id": str(e.get("id")),
		"latitud": float(e.get("latitud")),
		"longitud": float(e.get("longitud")),
		# Opcionales: pueden venir null/ausentes
		"DbmInternet": e.get("DbmInternet"),
		"TypeInternet": e.get("TypeInternet"),
		"BtteryLevel": float(e.get("BtteryLevel")),
		"Telefonia": e.get("Telefonia"),  # Entel | Tigo | Viva | null
	}

@csrf_exempt
def events_batch(request: HttpRequest):
	import logging
	logger = logging.getLogger("rastreo.views")
	if request.method != "POST":
		logger.warning("Método no permitido: %s", request.method)
		return JsonResponse({"error": "Only POST allowed"}, status=405)
	try:
		body = request.body.decode("utf-8")
		logger.info("Body recibido: %s", body)
		data = json.loads(body)
	except Exception as ex:
		logger.error("Error decodificando JSON: %s", ex)
		return JsonResponse({"error": f"Invalid JSON: {ex}"}, status=400)
	# Permitir también un solo objeto para comodidad en pruebas
	if isinstance(data, dict):
		data = [data]
	if not isinstance(data, list):
		logger.error("Formato de datos no válido: %s", type(data))
		return JsonResponse({"error": "Expected a JSON array or object"}, status=400)
	valid_events: List[Dict[str, Any]] = []
	rejected = 0
	for ev in data:
		if _validate_event(ev):
			valid_events.append(_normalize_event(ev))
		else:
			logger.warning("Evento rechazado: %s", ev)
			rejected += 1
	logger.info("Eventos válidos: %d, rechazados: %d", len(valid_events), rejected)
	if valid_events:
		coll = _get_collection()
		logger.info("Insertando en MongoDB: %s", valid_events)
		try:
			result = coll.insert_many(valid_events, ordered=False)
			inserted = len(result.inserted_ids)
			logger.info("Insertados en MongoDB: %d", inserted)
		except Exception as ex:
			logger.error("Error al insertar en MongoDB: %s", ex)
			return JsonResponse({"error": f"DB error: {ex}"}, status=500)
	else:
		inserted = 0
	return JsonResponse({"inserted": inserted, "rejected": rejected})
