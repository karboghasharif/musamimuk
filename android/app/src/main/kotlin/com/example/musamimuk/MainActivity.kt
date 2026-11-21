package com.musamimuk.app

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// FlutterFragmentActivity is required for RevenueCat Paywalls / Customer Center.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.musamimuk/google_maps",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApiKey" -> result.success(readMapsApiKey())
                "isConfigured" -> result.success(readMapsApiKey().isNotEmpty())
                else -> result.notImplemented()
            }
        }
    }

    private fun readMapsApiKey(): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA,
            )
            appInfo.metaData
                ?.getString("com.google.android.geo.API_KEY")
                ?.trim()
                .orEmpty()
        } catch (_: Exception) {
            ""
        }
    }
}
