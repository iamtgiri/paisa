package com.tanmoy.paisa

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

class NotificationCaptureService : NotificationListenerService() {
    override fun onNotificationPosted(statusBarNotification: StatusBarNotification) {
        if (statusBarNotification.packageName == packageName) return
        val preferences = getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE)
        if (!preferences.getBoolean(CAPTURE_ENABLED_KEY, false)) return

        val extras = statusBarNotification.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.joinToString(" ") { it.toString() }
            .orEmpty()
        val text = listOf(
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty(),
            lines,
            extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty(),
            extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString().orEmpty(),
        ).firstOrNull { it.isNotBlank() }.orEmpty()
        val message = listOf(title, text).filter { it.isNotBlank() }.joinToString(" - ")

        if (!looksLikeFinancialNotification(message)) return

        val queue = try {
            JSONArray(preferences.getString(QUEUE_KEY, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        while (queue.length() >= MAX_QUEUE_SIZE) {
            queue.remove(0)
        }

        queue.put(
            JSONObject()
                .put("packageName", statusBarNotification.packageName)
                .put("title", title)
                .put("text", text)
                .put("receivedAt", System.currentTimeMillis()),
        )
        preferences.edit().putString(QUEUE_KEY, queue.toString()).apply()
    }

    private fun looksLikeFinancialNotification(message: String): Boolean {
        val lower = message.lowercase(Locale.ROOT)
        val hasAmount = Regex("\\b(?:rs\\.?|inr)\\s*[\\d,]+(?:\\.\\d{1,2})?\\b")
            .containsMatchIn(lower)
        val hasFinancialEvent = Regex(
            "\\b(?:credited|debited|spent|sent|withdrawn)\\b",
        ).containsMatchIn(lower)
        return hasAmount && hasFinancialEvent
    }

    companion object {
        const val PREFERENCES_NAME = "paisa_notification_capture"
        const val CAPTURE_ENABLED_KEY = "capture_enabled"
        const val QUEUE_KEY = "captured_notifications"
        const val MAX_QUEUE_SIZE = 100
    }
}
