from django.test import TestCase, Client
import json


class EventsBatchTests(TestCase):
	def setUp(self):
		self.client = Client()

	def test_reject_non_array_non_object(self):
		resp = self.client.post('/api/events/batch', data=json.dumps(123), content_type='application/json')
		self.assertEqual(resp.status_code, 400)

	def test_insert_minimal_valid(self):
		payload = [{
			"id": "abc-123",
			"latitud": -17.0,
			"longitud": -63.0,
			"DbmInternet": -90,
			"TypeInternet": "4G",
			"BtteryLevel": 77.0
		}]
		resp = self.client.post('/api/events/batch', data=json.dumps(payload), content_type='application/json')
		self.assertEqual(resp.status_code, 200)
		body = resp.json()
		self.assertEqual(body['inserted'], 1)
		self.assertEqual(body['rejected'], 0)
