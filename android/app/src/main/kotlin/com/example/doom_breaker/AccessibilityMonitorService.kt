package com.example.doom_breaker

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.provider.Settings
import android.text.TextUtils
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import android.util.Log

class AccessibilityMonitorService : AccessibilityService() {

    companion object {
        private const val TAG = "AccessibilityMonitor"
        
        /**
         * Check if accessibility service is enabled
         */
        fun isEnabled(context: Context): Boolean {
            val expectedComponentName = "${context.packageName}/${AccessibilityMonitorService::class.java.name}"
            val enabledServicesSetting = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServicesSetting)

            while (colonSplitter.hasNext()) {
                val componentName = colonSplitter.next()
                if (componentName.equals(expectedComponentName, ignoreCase = true)) {
                    return true
                }
            }
            return false
        }
    }

    private var scrollCount = 0
    private var lastScrollTime = 0L
    private var currentPackage: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "🔌 Accessibility Service Connected")

        val info = AccessibilityServiceInfo().apply {
            // Capture ALL events to ensure we catch YouTube scrolls
            eventTypes = AccessibilityEvent.TYPE_VIEW_SCROLLED or
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_CLICKED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.CONTENT_CHANGE_TYPE_SUBTREE

            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 0 // 0ms = INSTANT real-time detection
        }

        serviceInfo = info
        Log.d(TAG, "✅ Accessibility Service configured with ALL event types")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return

        val pkg = event.packageName?.toString() ?: "unknown"
        
        // Social media apps we monitor
        val socialApps = listOf(
            "com.instagram.android",
            "com.facebook.katana", 
            "com.zhiliaoapp.musically",
            "com.twitter.android",
            "com.snapchat.android",
            "com.reddit.frontpage"
        )
        
        // Log events from social media apps
        if (socialApps.contains(pkg)) {
            Log.w(TAG, "📱 Social Media Event: $pkg type=${event.eventType}")
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // App changed - PRIMARY SOURCE OF TRUTH
                if (pkg != currentPackage && pkg != "android" && pkg != "com.android.systemui") {
                    currentPackage = pkg
                    
                    Log.d(TAG, "🔄 App changed to: $currentPackage")
                    
                    // Send to Flutter (app change event)
                    notifyAppChange(pkg)
                    
                    // Reset scroll counter when app changes
                    scrollCount = 0
                    lastScrollTime = System.currentTimeMillis()
                }
            }

            AccessibilityEvent.TYPE_VIEW_SCROLLED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // Handle both scroll and content change
                handleScrollEvent(event)
            }

            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                Log.d(TAG, "Click detected in: $currentPackage")
            }
        }
    }

    private fun handleScrollEvent(event: AccessibilityEvent) {
        val currentTime = System.currentTimeMillis()
        val timeDiff = currentTime - lastScrollTime

        // IMPORTANT: Only track scrolls in distracting apps!
        val distractingApps = listOf(
            "com.instagram.android",
            "com.facebook.katana",
            "com.zhiliaoapp.musically",
            "com.twitter.android",
            "com.snapchat.android",
            "com.reddit.frontpage"
        )

        // Ignore scrolls from system UI, settings, home, etc.
        if (!distractingApps.contains(currentPackage)) {
            return  // Don't track this app
        }

        // Reset counter if more than 2 seconds since last scroll
        if (timeDiff > 2000) {
            scrollCount = 0
        }

        scrollCount++
        lastScrollTime = currentTime

        // Calculate scroll speed (scrolls per second)
        val scrollSpeed = if (timeDiff > 0) {
            (scrollCount.toFloat() / (timeDiff / 1000f))
        } else {
            1f
        }

        // Log scroll
        Log.d(TAG, "📜 SCROLL: pkg=$currentPackage, count=$scrollCount, speed=${scrollSpeed.toInt()}")

        // Send EVERY scroll from distracting apps
        Log.w(TAG, "⚠️ SCROLLING! Count: $scrollCount, Speed: $scrollSpeed, App: $currentPackage")
        
        // Send to Flutter immediately
        notifyFlutter(
            packageName = currentPackage ?: "unknown",
            scrollCount = scrollCount,
            scrollSpeed = scrollSpeed
        )

        // Check vertical scroll (for reels detection)
        if (isVerticalScroll(event)) {
            Log.d(TAG, "📱 Vertical scroll (reels)")
        }
    }

    private fun isVerticalScroll(event: AccessibilityEvent): Boolean {
        // Check if scroll is primarily vertical
        return try {
            val scrollY = event.scrollY
            val scrollX = event.scrollX
            kotlin.math.abs(scrollY) > kotlin.math.abs(scrollX)
        } catch (e: Exception) {
            false
        }
    }

    private fun notifyFlutter(packageName: String, scrollCount: Int, scrollSpeed: Float) {
        try {
            val eventData = mapOf(
                "packageName" to packageName,
                "scrollCount" to scrollCount,
                "scrollSpeed" to scrollSpeed.toDouble(),
                "timestamp" to System.currentTimeMillis()
            )
            
            MainActivity.scrollEventSink?.success(eventData)
            Log.d(TAG, "✅ Sent to Flutter: $packageName, scrolls: $scrollCount, speed: $scrollSpeed")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending to Flutter: ${e.message}")
        }
    }

    private fun notifyAppChange(packageName: String) {
        try {
            val appName = UsageStatsHelper.getAppName(this, packageName)
            val eventData = mapOf(
                "packageName" to packageName,
                "appName" to appName,
                "timestamp" to System.currentTimeMillis(),
                "source" to "accessibility" // Mark as coming from AccessibilityService
            )
            
            MainActivity.appEventSink?.success(eventData)
            Log.d(TAG, "✅ App change sent to Flutter: $appName ($packageName)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending app change: ${e.message}")
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Accessibility Service Destroyed")
    }
}
