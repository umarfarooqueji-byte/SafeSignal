package com.safesignal.safesignal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives BOOT_COMPLETED broadcast — placeholder for future
 * persistent service initialization after phone restart.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Future: start monitoring service here
    }
}
