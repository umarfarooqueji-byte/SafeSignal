package com.safesignal.safesignal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.telephony.TelephonyManager
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.provider.ContactsContract
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager

/**
 * BroadcastReceiver that listens for incoming calls and shows
 * a SafeSignal overlay popup analyzing whether the caller is likely a scam.
 */
class CallReceiver : BroadcastReceiver() {

    companion object {
        // Known scam prefixes in India
        private val SCAM_PREFIXES = setOf(
            "140", "141", "142", "143", "144", // Telemarketing prefixes
            "160"  // Service/TRAI commercial
        )

        // Known safe prefixes (banks, TRAI, etc.)
        private val BANK_PREFIXES = setOf(
            "1800", "1860", "1900" // Toll-free
        )

        // Scam number patterns
        private val SCAM_PATTERNS = listOf(
            Regex("^\\+?0?1[0-9]{9,10}$"), // US-like numbers
            Regex("^00[0-9]{10,}$"),         // International with 00
        )

        private var overlayView: View? = null
        private var windowManager: WindowManager? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: "Unknown"

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                // Incoming call — analyze and show overlay
                val analysis = analyzeNumber(context, phoneNumber)
                showOverlay(context, phoneNumber, analysis)
            }
            TelephonyManager.EXTRA_STATE_IDLE,
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                // Call ended or picked up — dismiss overlay
                dismissOverlay()
            }
        }
    }

    private data class CallAnalysis(
        val verdict: String,        // "SAFE", "SCAM", "CAUTION"
        val confidence: Int,         // 0-100
        val reason: String,
        val emoji: String,
        val bgColor: Int,
        val textColor: Int,
        val displayName: String? = null // To hold real person name
    )
    
    private fun getContactName(context: Context, phoneNumber: String): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (context.checkSelfPermission(Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
                return null
            }
        }
        
        try {
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI, 
                Uri.encode(phoneNumber)
            )
            val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getString(0)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    private fun analyzeNumber(context: Context, number: String): CallAnalysis {
        val clean = number.replace(Regex("[\\s\\-()]+"), "")
        
        val contactName = getContactName(context, clean)
        if (contactName != null) {
            return CallAnalysis(
                verdict = "SAFE",
                confidence = 100,
                reason = "Real person — Saved in your contacts",
                emoji = "✅",
                bgColor = Color.parseColor("#1B5E20"),
                textColor = Color.WHITE,
                displayName = contactName
            )
        }

        // Check if number is empty / private / withheld
        if (clean.isEmpty() || clean == "Unknown" || clean == "-1") {
            return CallAnalysis(
                verdict = "CAUTION",
                confidence = 60,
                reason = "Private / Hidden number — caller ne apna number chhupaaya hai",
                emoji = "⚠️",
                bgColor = Color.parseColor("#F57F17"),
                textColor = Color.WHITE
            )
        }

        // Check known scam prefixes (India)
        for (prefix in SCAM_PREFIXES) {
            if (clean.startsWith(prefix)) {
                return CallAnalysis(
                    verdict = "SCAM",
                    confidence = 85,
                    reason = "Telemarketing / Promotional prefix $prefix — likely spam call",
                    emoji = "🔴",
                    bgColor = Color.parseColor("#C62828"),
                    textColor = Color.WHITE
                )
            }
        }

        // Toll-free / bank numbers
        for (prefix in BANK_PREFIXES) {
            if (clean.startsWith(prefix)) {
                return CallAnalysis(
                    verdict = "SAFE",
                    confidence = 80,
                    reason = "Toll-free number — likely bank ya company helpline",
                    emoji = "✅",
                    bgColor = Color.parseColor("#1B5E20"),
                    textColor = Color.WHITE
                )
            }
        }

        // Short numbers (government, services)
        if (clean.length in 3..5) {
            return CallAnalysis(
                verdict = "SAFE",
                confidence = 75,
                reason = "Short service number — government ya emergency service",
                emoji = "✅",
                bgColor = Color.parseColor("#1B5E20"),
                textColor = Color.WHITE
            )
        }

        // International format
        if (clean.startsWith("+") && !clean.startsWith("+91")) {
            return CallAnalysis(
                verdict = "CAUTION",
                confidence = 70,
                reason = "International number (+${clean.take(4)}) — verify karein",
                emoji = "⚠️",
                bgColor = Color.parseColor("#E65100"),
                textColor = Color.WHITE
            )
        }

        // Pattern matching
        for (pattern in SCAM_PATTERNS) {
            if (pattern.containsMatchIn(clean)) {
                return CallAnalysis(
                    verdict = "SCAM",
                    confidence = 72,
                    reason = "Suspicious number pattern detected",
                    emoji = "🔴",
                    bgColor = Color.parseColor("#C62828"),
                    textColor = Color.WHITE
                )
            }
        }

        // Default — local Indian number
        return CallAnalysis(
            verdict = "UNKNOWN",
            confidence = 50,
            reason = "Local number — SafeSignal ke paas is number ki info nahi",
            emoji = "❓",
            bgColor = Color.parseColor("#1565C0"),
            textColor = Color.WHITE
        )
    }

    private fun showOverlay(context: Context, phoneNumber: String, analysis: CallAnalysis) {
        if (!canDrawOverlay(context)) return

        Handler(Looper.getMainLooper()).post {
            try {
                dismissOverlay() // clear any existing overlay

                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                windowManager = wm

                // Build overlay view programmatically
                val container = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(40, 32, 40, 32)
                    setBackgroundColor(Color.parseColor("#CC000000"))
                    elevation = 24f
                }

                // Brand header
                val brandRow = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                }
                val shieldIcon = TextView(context).apply {
                    text = "🛡️"
                    textSize = 20f
                    setPadding(0, 0, 12, 0)
                }
                val brandText = TextView(context).apply {
                    text = "SafeSignal"
                    setTextColor(Color.WHITE)
                    textSize = 14f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                }
                brandRow.addView(shieldIcon)
                brandRow.addView(brandText)

                // Incoming call label
                val incomingLabel = TextView(context).apply {
                    text = "Incoming Call"
                    setTextColor(Color.parseColor("#90FFFFFF"))
                    textSize = 12f
                    setPadding(0, 16, 0, 4)
                }

                // Phone number or Contact Name
                val numberText = TextView(context).apply {
                    text = analysis.displayName ?: phoneNumber
                    setTextColor(Color.WHITE)
                    textSize = 22f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                }
                
                // If it's a known contact, also show the phone number small underneath
                var subNumberText: TextView? = null
                if (analysis.displayName != null) {
                    subNumberText = TextView(context).apply {
                        text = phoneNumber
                        setTextColor(Color.parseColor("#A0FFFFFF"))
                        textSize = 12f
                        setPadding(0, 0, 0, 8)
                    }
                }

                // Verdict badge
                val verdictBadge = TextView(context).apply {
                    text = "${analysis.emoji}  ${analysis.verdict}"
                    setTextColor(analysis.textColor)
                    setBackgroundColor(analysis.bgColor)
                    textSize = 14f
                    setTypeface(null, android.graphics.Typeface.BOLD)
                    setPadding(28, 12, 28, 12)
                }
                
                // Wrapper for badge to allow margins if needed
                val badgeWrapper = LinearLayout(context).apply {
                    setPadding(0, 12, 0, 0)
                    addView(verdictBadge)
                }

                // Reason
                val reasonText = TextView(context).apply {
                    text = analysis.reason
                    setTextColor(Color.parseColor("#CCFFFFFF"))
                    textSize = 12f
                    setPadding(0, 12, 0, 0)
                }

                container.addView(brandRow)
                container.addView(incomingLabel)
                container.addView(numberText)
                if (subNumberText != null) {
                    container.addView(subNumberText)
                }
                container.addView(badgeWrapper)
                container.addView(reasonText)

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    else
                        @Suppress("DEPRECATION")
                        WindowManager.LayoutParams.TYPE_PHONE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP
                    y = 80
                }

                wm.addView(container, params)
                overlayView = container

                // Auto-dismiss after 12 seconds
                Handler(Looper.getMainLooper()).postDelayed({ dismissOverlay() }, 12000)
            } catch (e: Exception) {
                // Silently fail — overlay is a nice-to-have
            }
        }
    }

    private fun dismissOverlay() {
        try {
            overlayView?.let { view ->
                windowManager?.removeView(view)
                overlayView = null
            }
        } catch (_: Exception) {}
    }

    private fun canDrawOverlay(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }
}
