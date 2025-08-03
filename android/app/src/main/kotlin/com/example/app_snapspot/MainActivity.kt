package com.example.app_snapspot

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app_snapspot/mapbox"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMapboxToken" -> {
                    val token = getMapboxToken()
                    if (token != null) {
                        result.success(token)
                    } else {
                        result.error("UNAVAILABLE", "Mapbox token không có trong AndroidManifest.xml", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getMapboxToken(): String? {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            val bundle = appInfo.metaData
            bundle?.getString("com.mapbox.token")
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}