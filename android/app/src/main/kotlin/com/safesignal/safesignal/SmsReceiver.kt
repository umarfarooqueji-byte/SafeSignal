package com.safesignal.safesignal

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import java.util.Locale

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL_ID = "safesignal_sms_alerts"
        private const val NOTIFICATION_ID = 2002
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (msg in messages) {
                val body = msg.messageBody ?: continue
                val sender = msg.originatingAddress ?: "Unknown"

                // Analyze SMS body
                val analysis = analyzeSms(body)
                if (analysis.isSuspicious) {
                    showScamNotification(context, sender, body, analysis.reason)
                }
            }
        } catch (e: Exception) {
            // fail silently
        }
    }

    private class SmsAnalysis(val isSuspicious: Boolean, val reason: String)

    private fun analyzeSms(body: String): SmsAnalysis {
        val lower = body.lowercase(Locale.getDefault())

        val scamKeywords = listOf(
            "arrest", "cbi", "police custody", "court warrant", "narcotics division",
            "electricity bill update", "power connection cut", "electricity cut",
            "won lucky draw", "kbc lottery", "won prize", "crore", "lakhs lucky",
            "account blocked", "suspend your card", "kyc details expired", "update pan card",
            "part time job", "earn money from home", "daily salary", "telegram like job",
            "unknown transaction", "deducted rupees", "transfer success"
        )

        for (kw in scamKeywords) {
            if (lower.contains(kw)) {
                return SmsAnalysis(true, "Scam Indicator detected: '$kw'")
            }
        }

        // Suspicious link + urgent words
        if (lower.contains("http") || lower.contains(".ru/") || lower.contains(".apk") || lower.contains("bit.ly") || lower.contains("tinyurl")) {
            val urgentWords = listOf("urgent", "immediately", "block", "verify", "claim", "last date")
            if (urgentWords.any { lower.contains(it) }) {
                return SmsAnalysis(true, "Suspicious link with urgent call-to-action")
            }
        }

        return SmsAnalysis(false, "")
    }

    private fun showScamNotification(context: Context, sender: String, body: String, reason: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SafeSignal SMS Scam Shield",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifies when a phishing/scam message is received"
            }
            nm.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle("🔴 SCAM ALERT: $sender")
            .setContentText("Khatra detected: $reason")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("SafeSignal detected a scam SMS from $sender:\n\n\"$body\"\n\n⚠️ Is message ke links pe click mat karein aur na hi kisi se OTP share karein!"))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        nm.notify(NOTIFICATION_ID + sender.hashCode(), notification)
    }
}
