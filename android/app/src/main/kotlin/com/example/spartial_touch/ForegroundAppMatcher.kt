package com.example.spartial_touch

import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi

/**
 * ForegroundAppMatcher polls Android UsageStats to determine which app is
 * currently in the foreground and notifies when it changes.
 *
 * Requires the "Package Usage Stats" special permission (not a runtime permission —
 * the user grants it from Settings > Apps > Special app access > Usage access).
 */
class ForegroundAppMatcher(
    private val context: Context,
    private val onAppChanged: (packageName: String) -> Unit
) {
    private val handler = Handler(Looper.getMainLooper())
    private var lastPackage: String = ""
    private var running = false

    // Poll every 1.5 seconds — fast enough for seamless profile switching
    private val pollIntervalMs = 1500L

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            val current = getForegroundPackage()
            if (current != null && current != lastPackage) {
                lastPackage = current
                Log.d("ForegroundAppMatcher", "Active app: $current")
                onAppChanged(current)
            }
            handler.postDelayed(this, pollIntervalMs)
        }
    }

    fun start() {
        if (running) return
        running = true
        handler.post(pollRunnable)
    }

    fun stop() {
        running = false
        handler.removeCallbacks(pollRunnable)
    }

    private fun getForegroundPackage(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            getForegroundPackageViaUsageStats()
        } else {
            @Suppress("DEPRECATION")
            (context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager)
                .getRunningTasks(1)
                .firstOrNull()
                ?.topActivity
                ?.packageName
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun getForegroundPackageViaUsageStats(): String? {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            now - 10_000L,
            now
        )
        return stats
            ?.filter { it.lastTimeUsed > 0 }
            ?.maxByOrNull { it.lastTimeUsed }
            ?.packageName
    }
}
