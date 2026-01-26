package com.example.doom_breaker

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

class MonitoringService : Service() {

    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "doom_breaker_monitoring"
        private const val CHANNEL_NAME = "Focus Monitoring"
        private const val CHECK_INTERVAL = 1000L // 1 second for fast detection
    }

    private var handler: Handler? = null
    private var monitoringRunnable: Runnable? = null
    private var lastCheckedApp: String? = null
    private var lastAppChangeTime: Long = 0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        lastAppChangeTime = System.currentTimeMillis()
        startMonitoring()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors app usage to help you stay focused"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Doom Breaker Active")
            .setContentText("Monitoring your focus...")
            .setSmallIcon(android.R.drawable.ic_menu_view) // Use proper icon in production
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startMonitoring() {
        handler = Handler(Looper.getMainLooper())
        
        monitoringRunnable = object : Runnable {
            override fun run() {
                checkCurrentApp()
                handler?.postDelayed(this, CHECK_INTERVAL)
            }
        }

        handler?.post(monitoringRunnable!!)
    }

    private fun checkCurrentApp() {
        // MonitoringService is DISABLED
        // Using only AccessibilityService for app detection
        // This method does nothing
        return
    }

    private fun stopMonitoring() {
        monitoringRunnable?.let {
            handler?.removeCallbacks(it)
        }
        handler = null
        monitoringRunnable = null
    }

    override fun onDestroy() {
        stopMonitoring()
        super.onDestroy()
    }
}
