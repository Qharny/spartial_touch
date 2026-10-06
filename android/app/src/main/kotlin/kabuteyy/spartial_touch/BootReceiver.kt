package kabuteyy.spartial_touch

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * After a reboot (or an app update), reminds the user that gesture control was on.
 *
 * Android 15+ forbids starting a camera foreground service from BOOT_COMPLETED, and on older
 * versions a camera service started from the background can't use the camera anyway, so the
 * service can't simply be restarted here. Tapping the notification opens the app, and
 * main.dart restarts the service because the user's toggle is still on.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val CHANNEL_ID = "resume_channel"
        private const val NOTIFICATION_ID = 2
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        val prefs = context.getSharedPreferences(GestureService.PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("service_enabled", false)) return

        try {
            val nm = context.getSystemService(NotificationManager::class.java) ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                nm.createNotificationChannel(
                    NotificationChannel(CHANNEL_ID, "Resume reminders", NotificationManager.IMPORTANCE_DEFAULT)
                )
            }
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_IMMUTABLE
            )
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("SpatialTouch is paused")
                .setContentText("Tap to turn gesture control back on.")
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
            nm.notify(NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted on Android 13+ — nothing else we can do here.
            Log.w("BootReceiver", "Cannot post resume notification", e)
        }
    }
}
