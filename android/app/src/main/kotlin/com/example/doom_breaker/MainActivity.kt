package com.example.doom_breaker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Build


class MainActivity: FlutterActivity() {
    private val MONITORING_CHANNEL = "com.doombreaker/monitoring"
    private val OVERLAY_CHANNEL = "com.doombreaker/overlay"
    private val PERMISSIONS_CHANNEL = "com.doombreaker/permissions"
    private val SCROLL_EVENT_CHANNEL = "com.doombreaker/scroll_events"
    private val APP_EVENT_CHANNEL = "com.doombreaker/app_events"
    
    private var methodChannel: MethodChannel? = null
    private var overlayChannel: MethodChannel? = null
    private var permissionsChannel: MethodChannel? = null

    companion object {
        var scrollEventSink: EventChannel.EventSink? = null
        var appEventSink: EventChannel.EventSink? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup monitoring channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MONITORING_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    // MonitoringService DISABLED - using only AccessibilityService
                    // AccessibilityService provides more accurate app detection
                    result.success(true)
                }
                "stopMonitoring" -> {
                    // MonitoringService DISABLED
                    result.success(true)
                }
                "getForegroundApp" -> {
                    val appPackage = UsageStatsHelper.getForegroundApp(this)
                    result.success(appPackage)
                }
                else -> result.notImplemented()
            }
        }

        // Setup overlay channel
        overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        overlayChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showWarning" -> {
                    val message = call.argument<String>("message") ?: "Take a break!"
                    OverlayService.showWarning(this, message)
                    result.success(true)
                }
                "showReminder" -> {
                    val message = call.argument<String>("message") ?: "Return to focus"
                    val countdown = call.argument<Int>("countdown") ?: 30
                    OverlayService.showReminder(this, message, countdown)
                    result.success(true)
                }
                "showBlock" -> {
                    val message = call.argument<String>("message") ?: "App blocked"
                    val duration = call.argument<Int>("duration") ?: 300
                    OverlayService.showBlock(this, message, duration)
                    result.success(true)
                }
                "hideOverlay" -> {
                    OverlayService.hide(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Setup permissions channel
        permissionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
        permissionsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAllPermissions" -> {
                    val permissions = mapOf(
                        "usageStats" to UsageStatsHelper.hasUsageStatsPermission(this),
                        "overlay" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else true,
                        "accessibility" to AccessibilityMonitorService.isEnabled(this),
                        "batteryOptimization" to isBatteryOptimizationDisabled(),
                        "autoStart" to true // Cannot check programmatically
                    )
                    result.success(permissions)
                }
                "checkUsageStatsPermission" -> {
                    val hasPermission = UsageStatsHelper.hasUsageStatsPermission(this)
                    result.success(hasPermission)
                }
                "requestUsageStatsPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    val hasPermission = AccessibilityMonitorService.isEnabled(this)
                    result.success(hasPermission)
                }
                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "checkBatteryOptimization" -> {
                    val isDisabled = isBatteryOptimizationDisabled()
                    result.success(isDisabled)
                }
                "requestBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "requestAutoStartPermission" -> {
                    // Open manufacturer-specific autostart settings
                    requestAutoStartPermission()
                    result.success(true)
                }
                "getInstalledApps" -> {
                    // Get list of installed apps (excluding system apps by default)
                    val includeSystem = call.argument<Boolean>("includeSystem") ?: false
                    val apps = UsageStatsHelper.getInstalledApps(this, includeSystem)
                    val appList = apps.map { appInfo ->
                        // Convert drawable icon to base64 PNG
                        val iconBase64 = try {
                            val drawable = appInfo.icon
                            val bitmap: android.graphics.Bitmap
                            
                            // Handle different drawable types including AdaptiveIconDrawable
                            if (drawable is android.graphics.drawable.BitmapDrawable) {
                                bitmap = drawable.bitmap
                            } else {
                                // For AdaptiveIconDrawable and other types
                                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                                bitmap = android.graphics.Bitmap.createBitmap(
                                    width, height, android.graphics.Bitmap.Config.ARGB_8888
                                )
                                val canvas = android.graphics.Canvas(bitmap)
                                drawable.setBounds(0, 0, canvas.width, canvas.height)
                                drawable.draw(canvas)
                            }
                            
                            // Scale down if needed for performance
                            val scaledBitmap = android.graphics.Bitmap.createScaledBitmap(bitmap, 72, 72, true)
                            
                            val stream = java.io.ByteArrayOutputStream()
                            scaledBitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                            android.util.Base64.encodeToString(stream.toByteArray(), android.util.Base64.NO_WRAP)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Failed to encode icon for ${appInfo.packageName}: ${e.message}")
                            ""
                        }
                        
                        mapOf(
                            "packageName" to appInfo.packageName,
                            "appName" to appInfo.appName,
                            "icon" to iconBase64
                        )
                    }
                    result.success(appList)
                }
                else -> result.notImplemented()
            }
        }

        // Setup scroll event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCROLL_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    scrollEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    scrollEventSink = null
                }
            })

        // Setup app event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, APP_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    appEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    appEventSink = null
                }
            })
    }

    /**
     * Check if battery optimization is disabled for this app
     */
    private fun isBatteryOptimizationDisabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            return pm.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

    /**
     * Request autostart permission for various manufacturers
     */
    private fun requestAutoStartPermission() {
        try {
            val manufacturer = Build.MANUFACTURER.lowercase()
            val intent = when {
                manufacturer.contains("xiaomi") -> {
                    Intent().apply {
                        component = android.content.ComponentName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.autostart.AutoStartManagementActivity"
                        )
                    }
                }
                manufacturer.contains("oppo") -> {
                    Intent().apply {
                        component = android.content.ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                        )
                    }
                }
                manufacturer.contains("vivo") -> {
                    Intent().apply {
                        component = android.content.ComponentName(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                        )
                    }
                }
                manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                    Intent().apply {
                        component = android.content.ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                        )
                    }
                }
                manufacturer.contains("samsung") -> {
                    Intent().apply {
                        component = android.content.ComponentName(
                            "com.samsung.android.lool",
                            "com.samsung.android.sm.ui.battery.BatteryActivity"
                        )
                    }
                }
                else -> {
                    // Fallback to general settings
                    Intent(Settings.ACTION_SETTINGS)
                }
            }
            startActivity(intent)
        } catch (e: Exception) {
            // If manufacturer-specific settings fail, open general settings
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (ex: Exception) {
                android.util.Log.e("MainActivity", "Failed to open settings: ${ex.message}")
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        overlayChannel?.setMethodCallHandler(null)
        permissionsChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
