package com.example.doom_breaker

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.util.Timer
import java.util.TimerTask

object OverlayService {
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var countdownTimer: Timer? = null

    /**
     * Show warning overlay (Level 1)
     */
    fun showWarning(context: Context, message: String) {
        hide(context)
        
        // Simple implementation - in production, use custom Flutter overlay
        // For now, we'll just indicate the service is working
        android.util.Log.d("OverlayService", "Warning: $message")
        
        // TODO: Implement actual overlay view
        // This requires creating XML layouts or programmatic views
    }

    /**
     * Show reminder with countdown (Level 2)
     */
    fun showReminder(context: Context, message: String, countdownSeconds: Int) {
        hide(context)
        
        android.util.Log.d("OverlayService", "Reminder: $message (${countdownSeconds}s)")
        
        // TODO: Implement countdown overlay
    }

    /**
     * Show block screen (Level 3)
     */
    fun showBlock(context: Context, message: String, durationSeconds: Int) {
        hide(context)
        
        android.util.Log.d("OverlayService", "Block: $message for ${durationSeconds}s")
        
        // TODO: Implement full-screen block overlay
        // This should prevent user from accessing the app
    }

    /**
     * Hide all overlays
     */
    fun hide(context: Context) {
        countdownTimer?.cancel()
        countdownTimer = null
        
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        overlayView = null
        windowManager = null
    }

    /**
     * Check if overlay permission is granted
     */
    fun hasPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.provider.Settings.canDrawOverlays(context)
        } else {
            true
        }
    }
}
