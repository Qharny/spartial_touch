package com.example.spartial_touch

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel

object GestureEventBus {
    var eventSink: EventChannel.EventSink? = null

    fun sendEvent(gesture: String) {
        // Must be called on main thread
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(gesture)
        }
    }
}

object CameraFrameEventBus {
    var eventSink: EventChannel.EventSink? = null

    fun sendFrame(bytes: ByteArray) {
        // Must be called on main thread
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(bytes)
        }
    }
}

class GestureService : Service() {
    private lateinit var handTracker: HandTracker
    private lateinit var cameraManager: BackgroundCameraManager

    override fun onCreate() {
        super.onCreate()
        startForegroundNotification()

        handTracker = HandTracker(this) { gesture ->
            GestureEventBus.sendEvent(gesture)
        }
        handTracker.init()

        cameraManager = BackgroundCameraManager(this) { bitmap, bytes, timestamp ->
            handTracker.processFrame(bitmap, timestamp)
            CameraFrameEventBus.sendFrame(bytes)
        }
        cameraManager.start()
    }

    override fun onDestroy() {
        cameraManager.stop()
        handTracker.close()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // Not a bound service
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun startForegroundNotification() {
        val channelId = "gesture_service_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Gesture Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Spatial Touch Gestures")
            .setContentText("Listening for hand gestures...")
            .setSmallIcon(android.R.drawable.ic_menu_camera) // You can replace with app icon
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
        } else {
            startForeground(1, notification)
        }
    }
}
