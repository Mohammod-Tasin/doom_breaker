package com.example.doom_breaker

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import java.util.*

object UsageStatsHelper {
    
    /**
     * Check if app has USAGE_STATS permission
     */
    fun hasUsageStatsPermission(context: Context): Boolean {
        return try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Get currently foreground app package name
     */
    fun getForegroundApp(context: Context): String? {
        if (!hasUsageStatsPermission(context)) {
            return null
        }

        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 1000 * 2 // Last 2 seconds (reduced from 10)

            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                beginTime,
                endTime
            )

            if (usageStatsList.isNullOrEmpty()) {
                return null
            }

            // Filter apps that were actually used in the last 1 second (more recent)
            val recentThreshold = endTime - 1000
            val recentApps = usageStatsList.filter { 
                it.lastTimeUsed >= recentThreshold && 
                it.packageName != "android" && // Exclude system
                it.packageName != "com.android.systemui" // Exclude system UI
            }

            // If we have recent apps, get the most recent one
            if (recentApps.isNotEmpty()) {
                val mostRecent = recentApps.maxByOrNull { it.lastTimeUsed }
                return mostRecent?.packageName
            }

            // Fallback: Get most recently used app from the 2-second window
            val recentApp = usageStatsList
                .filter { it.packageName != "android" && it.packageName != "com.android.systemui" }
                .maxByOrNull { it.lastTimeUsed }
            return recentApp?.packageName
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    /**
     * Get app usage statistics for a time range
     */
    fun getUsageStats(context: Context, beginTime: Long, endTime: Long): List<UsageStats> {
        if (!hasUsageStatsPermission(context)) {
            return emptyList()
        }

        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            return usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                beginTime,
                endTime
            ) ?: emptyList()
        } catch (e: Exception) {
            e.printStackTrace()
            return emptyList()
        }
    }

    /**
     * Get app name from package name
     */
    fun getAppName(context: Context, packageName: String): String {
        return try {
            val packageManager = context.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    /**
     * Get list of installed apps (excluding system apps)
     */
    fun getInstalledApps(context: Context, includeSystemApps: Boolean = false): List<AppInfo> {
        val packageManager = context.packageManager
        val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        
        return packages
            .filter { includeSystemApps || (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .map { appInfo ->
                AppInfo(
                    packageName = appInfo.packageName,
                    appName = packageManager.getApplicationLabel(appInfo).toString(),
                    icon = appInfo.loadIcon(packageManager)
                )
            }
            .sortedBy { it.appName }
    }

    data class AppInfo(
        val packageName: String,
        val appName: String,
        val icon: android.graphics.drawable.Drawable
    )
}
