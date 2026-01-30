package com.example.doom_breaker

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Timer
import java.util.TimerTask

/**
 * Overlay Service for displaying intervention overlays
 * Three levels: Warning (subtle), Reminder (modal), Block (full-screen)
 */
object OverlayService {
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var countdownTimer: Timer? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Colors
    private const val COLOR_WARNING = 0xFFFFA726.toInt()  // Orange
    private const val COLOR_REMINDER = 0xFFFF7043.toInt() // Deep Orange
    private const val COLOR_BLOCK = 0xFFE53935.toInt()    // Red
    private const val COLOR_DARK_BG = 0xE6121212.toInt()  // Dark semi-transparent

    /**
     * Show warning overlay (Level 1) - Subtle banner at top
     */
    fun showWarning(context: Context, message: String, autoDismissMs: Long = 3000) {
        mainHandler.post {
            hide(context)
            
            if (!hasPermission(context)) {
                android.util.Log.e("OverlayService", "No overlay permission!")
                return@post
            }

            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create warning banner
            val banner = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dpToPx(context, 16), dpToPx(context, 12), dpToPx(context, 16), dpToPx(context, 12))
                
                val bg = GradientDrawable().apply {
                    setColor(COLOR_WARNING)
                    cornerRadius = dpToPx(context, 8).toFloat()
                }
                background = bg
                elevation = dpToPx(context, 4).toFloat()
            }

            // Warning icon (using text emoji for simplicity)
            val icon = TextView(context).apply {
                text = "⚠️"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                setPadding(0, 0, dpToPx(context, 8), 0)
            }

            // Message text
            val messageView = TextView(context).apply {
                text = message
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }

            // Dismiss button
            val dismissBtn = TextView(context).apply {
                text = "✕"
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                setPadding(dpToPx(context, 8), 0, 0, 0)
                setOnClickListener { hide(context) }
            }

            banner.addView(icon)
            banner.addView(messageView)
            banner.addView(dismissBtn)

            overlayView = banner

            // Layout params for top banner
            val params = createLayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                Gravity.TOP or Gravity.CENTER_HORIZONTAL
            ).apply {
                y = dpToPx(context, 48) // Below status bar
            }

            windowManager?.addView(overlayView, params)

            // Auto-dismiss after delay
            mainHandler.postDelayed({ hide(context) }, autoDismissMs)
            
            android.util.Log.d("OverlayService", "Showing warning: $message")
        }
    }

    /**
     * Show reminder overlay (Level 2) - Center modal with countdown
     */
    fun showReminder(context: Context, message: String, countdownSeconds: Int = 10) {
        mainHandler.post {
            hide(context)
            
            if (!hasPermission(context)) {
                android.util.Log.e("OverlayService", "No overlay permission!")
                return@post
            }

            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create modal container
            val modal = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setPadding(dpToPx(context, 24), dpToPx(context, 32), dpToPx(context, 24), dpToPx(context, 24))
                
                val bg = GradientDrawable().apply {
                    setColor(COLOR_DARK_BG)
                    cornerRadius = dpToPx(context, 16).toFloat()
                    setStroke(dpToPx(context, 2), COLOR_REMINDER)
                }
                background = bg
                elevation = dpToPx(context, 8).toFloat()
            }

            // Icon
            val icon = TextView(context).apply {
                text = "🛑"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 48f)
                gravity = Gravity.CENTER
            }

            // Title
            val title = TextView(context).apply {
                text = "Take a Break"
                setTextColor(COLOR_REMINDER)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
                gravity = Gravity.CENTER
                setPadding(0, dpToPx(context, 16), 0, dpToPx(context, 8))
            }

            // Message
            val messageView = TextView(context).apply {
                text = message
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                gravity = Gravity.CENTER
            }

            // Countdown
            val countdown = TextView(context).apply {
                text = "Dismissing in ${countdownSeconds}s"
                setTextColor(Color.GRAY)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                gravity = Gravity.CENTER
                setPadding(0, dpToPx(context, 24), 0, dpToPx(context, 16))
                tag = "countdown"
            }

            // Close button
            val closeBtn = Button(context).apply {
                text = "I understand, let me continue"
                setTextColor(Color.WHITE)
                setBackgroundColor(COLOR_REMINDER)
                setOnClickListener { hide(context) }
            }

            modal.addView(icon)
            modal.addView(title)
            modal.addView(messageView)
            modal.addView(countdown)
            modal.addView(closeBtn)

            overlayView = modal

            // Layout params for center modal
            val params = createLayoutParams(
                dpToPx(context, 320),
                WindowManager.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )

            windowManager?.addView(overlayView, params)

            // Start countdown
            startCountdown(context, countdown, countdownSeconds)
            
            android.util.Log.d("OverlayService", "Showing reminder: $message")
        }
    }

    /**
     * Show block overlay (Level 3) - Full screen blocker
     */
    fun showBlock(context: Context, message: String, durationSeconds: Int = 30) {
        mainHandler.post {
            hide(context)
            
            if (!hasPermission(context)) {
                android.util.Log.e("OverlayService", "No overlay permission!")
                return@post
            }

            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // Create full-screen blocker
            val blocker = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(COLOR_DARK_BG)
                setPadding(dpToPx(context, 32), dpToPx(context, 48), dpToPx(context, 32), dpToPx(context, 48))
            }

            // Big stop icon
            val icon = TextView(context).apply {
                text = "🚫"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 72f)
                gravity = Gravity.CENTER
            }

            // Title
            val title = TextView(context).apply {
                text = "Break Time!"
                setTextColor(COLOR_BLOCK)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
                gravity = Gravity.CENTER
                setPadding(0, dpToPx(context, 24), 0, dpToPx(context, 12))
            }

            // Message
            val messageView = TextView(context).apply {
                text = message
                setTextColor(Color.WHITE)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                gravity = Gravity.CENTER
                setPadding(0, 0, 0, dpToPx(context, 16))
            }

            // Motivation text
            val motivation = TextView(context).apply {
                text = "\"The secret of getting ahead is getting started.\"\n— Mark Twain"
                setTextColor(Color.LTGRAY)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                gravity = Gravity.CENTER
                setPadding(dpToPx(context, 16), dpToPx(context, 24), dpToPx(context, 16), 0)
            }

            // Countdown
            val countdown = TextView(context).apply {
                text = "Please wait ${durationSeconds} seconds"
                setTextColor(Color.GRAY)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                gravity = Gravity.CENTER
                setPadding(0, dpToPx(context, 32), 0, 0)
                tag = "countdown"
            }

            blocker.addView(icon)
            blocker.addView(title)
            blocker.addView(messageView)
            blocker.addView(motivation)
            blocker.addView(countdown)

            overlayView = blocker

            // Layout params for full screen
            val params = createLayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                Gravity.CENTER
            ).apply {
                // Make it truly full screen
                flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            }

            windowManager?.addView(overlayView, params)

            // Start countdown - auto dismiss after duration
            startBlockCountdown(context, countdown, durationSeconds)
            
            android.util.Log.d("OverlayService", "Showing block: $message for ${durationSeconds}s")
        }
    }

    /**
     * Hide all overlays
     */
    fun hide(context: Context) {
        mainHandler.post {
            countdownTimer?.cancel()
            countdownTimer = null
            
            overlayView?.let { view ->
                try {
                    windowManager?.removeView(view)
                    android.util.Log.d("OverlayService", "Overlay hidden")
                } catch (e: Exception) {
                    android.util.Log.e("OverlayService", "Error hiding overlay: ${e.message}")
                }
            }
            
            overlayView = null
        }
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

    // ========== Helper Functions ==========

    private fun createLayoutParams(width: Int, height: Int, gravity: Int): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        return WindowManager.LayoutParams(
            width,
            height,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            this.gravity = gravity
        }
    }

    private fun startCountdown(context: Context, countdownView: TextView, seconds: Int) {
        var remaining = seconds
        countdownTimer = Timer()
        countdownTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                remaining--
                mainHandler.post {
                    if (remaining > 0) {
                        countdownView.text = "Dismissing in ${remaining}s"
                    } else {
                        hide(context)
                    }
                }
            }
        }, 1000, 1000)
    }

    private fun startBlockCountdown(context: Context, countdownView: TextView, seconds: Int) {
        var remaining = seconds
        countdownTimer = Timer()
        countdownTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                remaining--
                mainHandler.post {
                    if (remaining > 0) {
                        countdownView.text = "Please wait $remaining seconds"
                    } else {
                        hide(context)
                    }
                }
            }
        }, 1000, 1000)
    }

    private fun dpToPx(context: Context, dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }
}
