package com.safesignal.safesignal

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.safesignal/app_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> result.success(getInstalledApps())
                    "getWifiSecurityType" -> result.success(getWifiSecurityType())
                    "openWifiSettings" -> {
                        openWifiSettings()
                        result.success(null)
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                android.provider.Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                android.net.Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    }
                    "isNotificationListenerEnabled" -> {
                        result.success(isNotificationListenerEnabled())
                    }
                    "openNotificationSettings" -> {
                        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─── Installed Apps ──────────────────────────────────────────────────────
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val installedApps = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        val apps = mutableListOf<Map<String, Any>>()

        val systemSkip = setOf(
            "android", "com.android.systemui", "com.android.settings",
            "com.android.phone", "com.android.inputmethod.latin"
        )

        for (pkg in installedApps) {
            val appInfo = pkg.applicationInfo ?: continue
            val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            val hasLauncher = pm.getLaunchIntentForPackage(pkg.packageName) != null

            if (!hasLauncher && isSystem) continue
            if (pkg.packageName in systemSkip) continue

            val permissions = pkg.requestedPermissions?.toList() ?: emptyList()
            val appName = pm.getApplicationLabel(appInfo).toString()

            apps.add(
                mapOf(
                    "name" to appName,
                    "package" to pkg.packageName,
                    "permissions" to permissions,
                    "isSystem" to isSystem,
                    "versionName" to (pkg.versionName ?: ""),
                )
            )
        }
        return apps
    }

    // ─── WiFi Security Type ──────────────────────────────────────────────────
    @Suppress("DEPRECATION")
    private fun getWifiSecurityType(): String {
        return try {
            val wifiManager =
                applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                    ?: return "Unknown"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+ — use getCurrentNetwork capabilities
                val networkCapabilities = wifiManager.connectionInfo
                val secType = networkCapabilities?.currentSecurityType ?: -1
                return when (secType) {
                    // WifiInfo.SECURITY_TYPE_OPEN
                    0 -> "Open"
                    // WifiInfo.SECURITY_TYPE_WEP
                    1 -> "WEP"
                    // WifiInfo.SECURITY_TYPE_PSK (WPA2)
                    2 -> "WPA2-PSK"
                    // WifiInfo.SECURITY_TYPE_EAP
                    3 -> "WPA2-EAP"
                    // WifiInfo.SECURITY_TYPE_SAE (WPA3)
                    4 -> "WPA3-SAE"
                    // WifiInfo.SECURITY_TYPE_OWE
                    5 -> "WPA3-OWE"
                    // WifiInfo.SECURITY_TYPE_WAPI_PSK
                    6 -> "WAPI-PSK"
                    else -> "WPA2"
                }
            } else {
                // Below Android 12 — scan results (need location permission)
                val scanResults = wifiManager.scanResults ?: return "WPA2"
                val connectionInfo = wifiManager.connectionInfo
                val connectedBssid = connectionInfo?.bssid

                val connectedScan = scanResults.find { it.BSSID == connectedBssid }
                val cap = connectedScan?.capabilities ?: ""

                return when {
                    cap.contains("WPA3") -> "WPA3-SAE"
                    cap.contains("WPA2") -> "WPA2-PSK"
                    cap.contains("WPA") -> "WPA-PSK"
                    cap.contains("WEP") -> "WEP"
                    cap.isEmpty() || cap == "[ESS]" || cap == "[IBSS]" -> "Open"
                    else -> "WPA2"
                }
            }
        } catch (e: Exception) {
            "WPA2"
        }
    }

    // ─── Open WiFi Settings ──────────────────────────────────────────────────
    private fun openWifiSettings() {
        val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    // ─── Notification Listener Check ─────────────────────────────────────────
    private fun isNotificationListenerEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!flat.isNullOrEmpty()) {
            val names = flat.split(":")
            for (name in names) {
                val componentName = android.content.ComponentName.unflattenFromString(name)
                if (componentName != null && componentName.packageName == pkgName) {
                    return true
                }
            }
        }
        return false
    }
}
