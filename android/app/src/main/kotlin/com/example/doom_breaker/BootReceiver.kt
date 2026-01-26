package com.example.doom_breaker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Boot receiver to start the monitoring service automatically on device boot
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d(TAG, "Device booted - MonitoringService disabled, using only AccessibilityService")
            
            // MonitoringService DISABLED - Only AccessibilityService is used
            // AccessibilityService will auto-start if user has enabled it in settings
            // No need to start any service here
        }
    }
}
