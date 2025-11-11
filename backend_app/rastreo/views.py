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
	collection = _mongo_client[db_name]["events"]
	return collection

# Nuevo esquema mínimo solicitado
# Campos: id, latitud, longitud, DbmInternet, TypeInternet, BtteryLevel
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
	}

@csrf_exempt
def events_batch(request: HttpRequest):
	if request.method != "POST":
		return JsonResponse({"error": "Only POST allowed"}, status=405)
	try:
		body = request.body.decode("utf-8")
		data = json.loads(body)
	except Exception as ex:
		return JsonResponse({"error": f"Invalid JSON: {ex}"}, status=400)
	# Permitir también un solo objeto para comodidad en pruebas
	if isinstance(data, dict):
		data = [data]
	if not isinstance(data, list):
		return JsonResponse({"error": "Expected a JSON array or object"}, status=400)
	valid_events: List[Dict[str, Any]] = []
	rejected = 0
	for ev in data:
		if _validate_event(ev):
			valid_events.append(_normalize_event(ev))
		else:
			rejected += 1
	if valid_events:
		coll = _get_collection()
		try:
			result = coll.insert_many(valid_events, ordered=False)
			inserted = len(result.inserted_ids)
		except Exception as ex:
			return JsonResponse({"error": f"DB error: {ex}"}, status=500)
	else:
		inserted = 0
	return JsonResponse({"inserted": inserted, "rejected": rejected})
