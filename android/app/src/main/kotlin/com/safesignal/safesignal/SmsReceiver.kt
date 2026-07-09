package com.safesignal.safesignal

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.Locale
import java.util.regex.Pattern

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL_ID = "safesignal_sms_alerts"
        private const val NOTIFICATION_ID_BASE = 2002
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREFS_KEY = "flutter.sms_inbox"
        private const val MAX_STORED = 200
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (msg in messages) {
                val body = msg.messageBody ?: continue
                val sender = msg.originatingAddress ?: "Unknown"
                val analysis = analyzeSms(body, sender)
                
                // ── Save to SharedPreferences for Flutter to read ──────────
                saveSmsToInbox(context, sender, body, analysis)
                
                // ── Show notification ──────────────────────────────────────
                if (analysis.isSuspicious) {
                    showScamNotification(context, sender, body, analysis)
                } else {
                    showSafeNotification(context, sender, body, analysis)
                }
            }
        } catch (e: Exception) {
            // fail silently
        }
    }

    // ─── Save SMS to Flutter SharedPreferences ────────────────────────────────
    private fun saveSmsToInbox(
        context: Context, sender: String, body: String, analysis: SmsAnalysis
    ) {
        try {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = prefs.getString(PREFS_KEY, "[]")
            val arr = JSONArray(existing)

            val record = JSONObject().apply {
                put("sender", sender)
                put("body", body)
                put("verdict", analysis.verdict)
                put("confidence", analysis.confidence)
                put("reason", analysis.reason)
                put("receivedAt", Instant.now().toString())
            }

            // Insert at beginning (newest first)
            val newArr = JSONArray()
            newArr.put(record)
            for (i in 0 until minOf(arr.length(), MAX_STORED - 1)) {
                newArr.put(arr.get(i))
            }

            prefs.edit().putString(PREFS_KEY, newArr.toString()).apply()
        } catch (e: Exception) {
            // fail silently — never crash on SMS storage failure
        }
    }

    private fun showSafeNotification(
        context: Context, sender: String, body: String, analysis: SmsAnalysis
    ) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SafeSignal SMS Scam Shield",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Real-time SMS scam detection alerts"
            }
            nm.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.presence_online)
            .setContentTitle("🟢 Safe SMS — $sender")
            .setContentText("Message is secure. No scam detected.")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("🟢 SafeSignal: Message Verified Secure")
                    .bigText(
                        "From: $sender\n\n" +
                        "Message: \"${body.take(200)}${if (body.length > 200) "..." else ""}\"\n\n" +
                        "✅ Verdict: SECURE & CLEAN\n" +
                        "SafeSignal analyzed this SMS and found no suspicious links or scam keywords."
                    )
                    .setSummaryText("SafeSignal Shield")
            )
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(android.graphics.Color.GREEN)
            .build()

        nm.notify(NOTIFICATION_ID_BASE + sender.hashCode(), notification)
    }

    // ─── Analysis Result ─────────────────────────────────────────────────────
    private data class SmsAnalysis(
        val isSuspicious: Boolean,
        val verdict: String,        // "SCAM" | "CAUTION" | "SAFE"
        val confidence: Int,        // 0-100
        val reason: String,
        val category: String        // human-readable category
    )

    // ─── Core Analysis Engine ─────────────────────────────────────────────────
    private fun analyzeSms(body: String, sender: String): SmsAnalysis {
        val lower = body.lowercase(Locale.getDefault())
        var score = 0
        val detectedReasons = mutableListOf<String>()

        // ── TIER 1: High-confidence fraud patterns (each +35 score) ──────────
        val tier1 = mapOf(
            "digital arrest" to "Digital Arrest scam",
            "arrested" to "Arrest threat",
            "cbi officer" to "Fake CBI officer",
            "narcotics" to "Fake narcotics case",
            "police custody" to "Fake police custody threat",
            "court warrant" to "Fake court warrant",
            "money laundering" to "Money laundering scam",
            "cyber crime notice" to "Fake cybercrime notice",
            "ed notice" to "Fake ED notice",
            "income tax notice" to "Fake IT notice",
            "kbc lottery" to "KBC lottery scam",
            "won lucky draw" to "Lucky draw fraud",
            "won prize" to "Prize scam",
            "claim your reward" to "Reward scam",
            "electricity cut" to "Electricity bill scam",
            "bijli katne" to "Bijli katne scam",
            "aadhaar blocked" to "Aadhaar block scam",
            "sim card blocked" to "SIM block scam",
            "kyc expire" to "KYC expiry scam",
            "update pan card" to "PAN card scam",
            "account suspend" to "Account suspension scam",
            "part time job" to "Fake job fraud",
            "telegram like job" to "Telegram like-job scam",
            "earn from home" to "Work-from-home fraud",
            "daily salary" to "Daily salary scam",
            "transfer success rs" to "Fake transaction alert",
            "unknown transaction" to "Fake transaction alert",
            "otp share" to "OTP phishing",
            "share otp" to "OTP phishing"
        )

        for ((keyword, reason) in tier1) {
            if (lower.contains(keyword)) {
                score += 35
                detectedReasons.add(reason)
            }
        }

        // ── TIER 2: Medium-confidence indicators (each +20 score) ─────────
        val tier2 = listOf(
            "click here", "tap here", "click link", "click now",
            "verify account", "verify your", "update account",
            "account blocked", "card blocked", "bank account block",
            "crore", "lakh prize", "won rs", "gift rs",
            "immediate action", "last chance", "expires today",
            "debit card", "credit card fraud", "upi fraud",
            "refund amount", "cashback credited"
        )
        for (kw in tier2) {
            if (lower.contains(kw)) {
                score += 20
                detectedReasons.add("Urgency/pressure tactic: '$kw'")
                break
            }
        }

        // ── TIER 3: Suspicious links + urgency combo (+30 score) ──────────
        val hasLink = lower.contains("http") || lower.contains("www.")
            || lower.contains(".apk") || lower.contains("bit.ly")
            || lower.contains("tinyurl") || lower.contains(".ru/")
            || lower.contains(".xyz/") || lower.contains(".tk/")
        val urgentWords = listOf("urgent", "immediately", "block", "verify", "claim", "last date", "expire", "today only")
        val hasUrgency = urgentWords.any { lower.contains(it) }

        if (hasLink && hasUrgency) {
            score += 30
            detectedReasons.add("Suspicious link with urgent call-to-action")
        } else if (hasLink && lower.contains(".apk")) {
            score += 40
            detectedReasons.add("APK download link — highly dangerous!")
        }

        // ── TIER 4: Sender number analysis ───────────────────────────────
        val cleanSender = sender.replace(Regex("[\\s\\-()]+"), "")
        if (cleanSender.startsWith("+") && !cleanSender.startsWith("+91")) {
            score += 15
            detectedReasons.add("International number sender")
        }

        // ── SAFE INDICATORS (reduce score) ───────────────────────────────
        val safeIndicators = listOf(
            "your transaction of", "credited to your", "debited from your",
            "upi ref no", "upi ref", "neft transfer", "imps transfer",
            "hdfc bank", "sbi bank", "axis bank", "icici bank",
            "do not share otp with anyone", "never share otp"
        )
        val isSafeContext = safeIndicators.any { lower.contains(it) }
        if (isSafeContext) {
            score = (score * 0.4).toInt()
        }

        // ── Verdict ───────────────────────────────────────────────────────
        val reasonText = detectedReasons.take(2).joinToString("; ")
        return when {
            score >= 60 -> SmsAnalysis(
                true, "SCAM", score.coerceAtMost(99),
                if (reasonText.isNotEmpty()) reasonText else "Multiple scam indicators detected",
                "Scam SMS Detected"
            )
            score in 35..59 -> SmsAnalysis(
                true, "CAUTION", score,
                detectedReasons.firstOrNull() ?: "Suspicious content found",
                "Suspicious SMS"
            )
            else -> SmsAnalysis(
                false, "SAFE", maxOf(5, 100 - score),
                if (isSafeContext) "Legitimate banking/service message detected" else "No scam patterns found",
                "Safe Message"
            )
        }
    }

    // ─── Notification Builder ─────────────────────────────────────────────────
    private fun showScamNotification(
        context: Context, sender: String, body: String, analysis: SmsAnalysis
    ) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SafeSignal SMS Scam Shield",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time SMS scam detection alerts"
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.RED
            }
            nm.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val emoji = when (analysis.verdict) {
            "SCAM" -> "\uD83D\uDD34"
            "CAUTION" -> "⚠\uFE0F"
            else -> "\uD83D\uDD35"
        }

        val confidenceStr = "${analysis.confidence}% confidence"
        val safetyTip = when (analysis.verdict) {
            "SCAM" -> "Kisi bhi link pe click mat karein aur na hi OTP/bank details share karein. 1930 pe call karein."
            else -> "Is message ke sath sawdhan rahein. Koi bhi link ya attachment pe click karne se pehle verify karein."
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle("$emoji ${analysis.category} — $sender")
            .setContentText(analysis.reason)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("$emoji SafeSignal: ${analysis.verdict} SMS ($confidenceStr)")
                    .bigText(
                        "From: $sender\n\n" +
                        "Message: \"${body.take(200)}${if (body.length > 200) "..." else ""}\"\n\n" +
                        "⚠\uFE0F Reason: ${analysis.reason}\n\n" +
                        "\uD83D\uDEA8 $safetyTip"
                    )
                    .setSummaryText("SafeSignal Scam Shield")
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(if (analysis.verdict == "SCAM") android.graphics.Color.RED else android.graphics.Color.parseColor("#FF6F00"))
            .build()

        nm.notify(NOTIFICATION_ID_BASE + sender.hashCode(), notification)
    }
}
