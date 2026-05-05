package com.example.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import org.json.JSONArray

private const val CHANNEL_ID = "scam_call_warning"
private const val CHANNEL_NAME = "Scam Call Warnings"

@RequiresApi(Build.VERSION_CODES.Q)
class ScamCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val number = callDetails.handle?.schemeSpecificPart ?: run {
            allowCall(callDetails)
            return
        }

        val scamPhones = loadCachedPhones()
        if (isScam(number, scamPhones)) {
            logScreened(number)
            postScamWarning(number)
            // Silence the ringer but let the call through — user decides on native call screen
            respondToCall(
                callDetails,
                CallResponse.Builder()
                    .setDisallowCall(false)
                    .setSilenceCall(true)
                    .setSkipCallLog(false)
                    .setSkipNotification(false)
                    .build(),
            )
        } else {
            allowCall(callDetails)
        }
    }

    private fun allowCall(callDetails: Call.Details) {
        respondToCall(callDetails, CallResponse.Builder().build())
    }

    private fun postScamWarning(number: String) {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Warns about incoming calls from known scam numbers" }
            nm.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("⚠️ Potential Scam Call")
            .setContentText("Incoming call from $number matches a known scam number.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        nm.notify(number.hashCode(), notification)
    }

    private fun loadCachedPhones(): Set<String> {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val json = prefs.getString("flutter.scam_phones", "[]") ?: "[]"
        return try {
            val arr = JSONArray(json)
            buildSet { repeat(arr.length()) { add(arr.getString(it)) } }
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun isScam(number: String, scamPhones: Set<String>): Boolean {
        val normalized = number.replace(Regex("[^+0-9]"), "")
        return scamPhones.any { it.replace(Regex("[^+0-9]"), "") == normalized }
    }

    private fun logScreened(number: String) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val json = prefs.getString("flutter.blocked_calls", "[]") ?: "[]"
        val arr = try { JSONArray(json) } catch (_: Exception) { JSONArray() }

        val entry = org.json.JSONObject().apply {
            put("number", number)
            put("blockedAt", System.currentTimeMillis())
        }
        arr.put(entry)

        // Cap log at 100 entries (oldest removed first)
        val capped = if (arr.length() > 100) {
            val trimmed = JSONArray()
            val start = arr.length() - 100
            for (i in start until arr.length()) trimmed.put(arr.get(i))
            trimmed
        } else arr

        prefs.edit().putString("flutter.blocked_calls", capped.toString()).apply()
    }
}
