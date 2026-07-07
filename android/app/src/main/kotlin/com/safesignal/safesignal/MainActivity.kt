package com.safesignal.safesignal

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.safesignal/app_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val installedApps = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        val apps = mutableListOf<Map<String, Any>>()

        // System packages to skip
        val systemSkip = setOf(
            "android", "com.android.systemui", "com.android.settings",
            "com.android.phone", "com.android.inputmethod.latin"
        )

        for (pkg in installedApps) {
            val appInfo = pkg.applicationInfo ?: continue
            // Skip pure system apps without launcher icon
            val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            val hasLauncher = pm.getLaunchIntentForPackage(pkg.packageName) != null

            // Include user apps + system apps that are launchable
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
}
