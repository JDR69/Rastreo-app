package com.example.movil_app

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app.telefonia"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "getCarrierName") {
				val tm = applicationContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager?
				val name = try {
					tm?.networkOperatorName
				} catch (e: Exception) {
					null
				}
				if (name.isNullOrBlank()) {
					result.success(null)
				} else {
					// Normalizar a valores esperados Entel | Tigo | Viva si coincide parcialmente
					val normalized = when {
						name.contains("entel", true) -> "Entel"
						name.contains("tigo", true) -> "Tigo"
						name.contains("viva", true) -> "Viva"
						else -> name
					}
					result.success(normalized)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
