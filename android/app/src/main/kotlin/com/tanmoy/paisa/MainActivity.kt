package com.tanmoy.paisa

import android.content.Intent
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
	private val channelName = "paisa/notification_capture"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"isAccessEnabled" -> result.success(isNotificationAccessEnabled())
					"openAccessSettings" -> {
						startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
						result.success(null)
					}
					"setCaptureEnabled" -> {
						val enabled = call.arguments as? Boolean ?: false
						getSharedPreferences(
							NotificationCaptureService.PREFERENCES_NAME,
							MODE_PRIVATE,
						).edit()
							.putBoolean(
								NotificationCaptureService.CAPTURE_ENABLED_KEY,
								enabled,
							)
							.apply()
						result.success(null)
					}
					"readCaptured" -> result.success(readCaptured())
					"clearCaptured" -> {
						getSharedPreferences(
							NotificationCaptureService.PREFERENCES_NAME,
							MODE_PRIVATE,
						).edit().remove(NotificationCaptureService.QUEUE_KEY).apply()
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun isNotificationAccessEnabled(): Boolean {
		return NotificationManagerCompat.getEnabledListenerPackages(this)
			.contains(packageName)
	}

	private fun readCaptured(): List<Map<String, Any>> {
		val preferences = getSharedPreferences(
			NotificationCaptureService.PREFERENCES_NAME,
			MODE_PRIVATE,
		)
		val queue = try {
			JSONArray(preferences.getString(NotificationCaptureService.QUEUE_KEY, "[]"))
		} catch (_: Exception) {
			JSONArray()
		}
		return (0 until queue.length()).map { index ->
			val item = queue.getJSONObject(index)
			mapOf(
				"packageName" to item.optString("packageName"),
				"title" to item.optString("title"),
				"text" to item.optString("text"),
				"receivedAt" to item.optLong("receivedAt"),
			)
		}
	}
}
