package com.example.movil_app

import android.content.Context
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app.telefonia"
	private val SIGNAL_CHANNEL = "app.signal"

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

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SIGNAL_CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "getSignalDbm") {
				val tm = applicationContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager?
				try {
					val infos = tm?.allCellInfo
					if (infos != null && infos.isNotEmpty()) {
						val info = infos.firstOrNull { it.isRegistered }
						if (info != null) {
							val dbm = when (info) {
								is android.telephony.CellInfoGsm -> info.cellSignalStrength.dbm
								is android.telephony.CellInfoCdma -> info.cellSignalStrength.dbm
								is android.telephony.CellInfoLte -> info.cellSignalStrength.dbm
								is android.telephony.CellInfoWcdma -> info.cellSignalStrength.dbm
								else -> null
							}
							result.success(dbm)
							return@setMethodCallHandler
						}
					}
				} catch (e: Exception) {
					// ignore
				}
				result.success(null)
			} else {
				result.notImplemented()
			}
		}
	}
}
