package com.example.spartial_touch

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
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
    private lateinit var smartWake: SmartWakeManager
    private lateinit var overlay: OverlayManager
    private lateinit var appMatcher: ForegroundAppMatcher
    val actionDispatcher by lazy { ActionDispatcher(this) }

    private var isCameraRunning = false
    private var isSmartWakeEnabled = true
    private val profileCache = mutableMapOf<String, Map<String, String>>()
    private var activeProfilePackage = "__default__"

    companion object {
        var instance: GestureService? = null
            private set
    }

    fun getActiveProfileName(): String {
        val pkg = activeProfilePackage
        if (pkg == "__default__") return "Default"
        return try {
            val pm = packageManager
            val info = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            pkg.substringAfterLast('.')
                .replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        startForegroundNotification()

        // Load persisted calibration & performance settings
        val prefs = getSharedPreferences("spatialtouch_prefs", MODE_PRIVATE)
        val savedConfidence = prefs.getFloat("confidence_threshold", 0.75f)
        val savedMotion = prefs.getFloat("motion_threshold", 0.12f)
        GestureInterpreter.applyCalibration(savedConfidence, savedMotion)
        
        val savedCooldown = prefs.getLong("cooldown_ms", 800L)
        GestureInterpreter.applyCooldown(savedCooldown)

        // Floating overlay — shows engine status over other apps
        overlay = OverlayManager(this)
        overlay.show()
        overlay.setSleeping()

        // Hand tracker — calls back with "GESTURE:confidence" payload
        handTracker = HandTracker(this) { gesturePayload ->
            val rawKey = gesturePayload.substringBefore(':')
            val isEnabled = prefs.getBoolean("gesture_enabled_$rawKey", true)
            
            if (isEnabled || !isSmartWakeEnabled) {
                // Increment total gesture count in SharedPreferences
                val totalGestures = prefs.getInt("total_gesture_count", 0) + 1
                prefs.edit().putInt("total_gesture_count", totalGestures).apply()

                GestureEventBus.sendEvent(gesturePayload)
                // Dispatch action based on active profile mapping
                actionDispatcher.dispatch(gesturePayload)
                // Haptic feedback if enabled
                val hapticsEnabled = prefs.getBoolean("haptics_enabled", true)
                if (hapticsEnabled) {
                    HapticService.pulse(this, "medium")
                }
                // Extract gesture name for overlay flash
                val gestureName = rawKey
                    .split('_')
                    .joinToString(" ") { it.lowercase().replaceFirstChar(Char::uppercaseChar) }
                overlay.flashGesture(gestureName)
            }
        }
        handTracker.init()

        // Camera — only processes frames when SmartWake says so
        cameraManager = BackgroundCameraManager(this) { bitmap, bytes, timestamp ->
            handTracker.processFrame(bitmap, timestamp)
            CameraFrameEventBus.sendFrame(bytes)
        }

        // ForegroundAppMatcher — auto-switch profiles when app changes
        appMatcher = ForegroundAppMatcher(this) { packageName ->
            activeProfilePackage = packageName
            val mappings = profileCache[packageName]
                ?: profileCache["__default__"]
                ?: emptyMap()
            actionDispatcher.setMappings(mappings)
            Log.d("GestureService", "Profile switched → $packageName")
        }
        appMatcher.start()

        // SmartWake — gates camera on proximity + accelerometer
        smartWake = SmartWakeManager(
            context = this,
            onWake = {
                if (!isCameraRunning) {
                    isCameraRunning = true
                    cameraManager.start()
                    overlay.setActive()
                }
            },
            onSleep = {
                if (isCameraRunning && isSmartWakeEnabled) {
                    isCameraRunning = false
                    cameraManager.stop()
                    overlay.setSleeping()
                }
            }
        )
        smartWake.start()
    }

    /** Enables or disables smart wake proximity gating dynamically (e.g. for testing screen). */
    fun setSmartWakeEnabled(enabled: Boolean) {
        isSmartWakeEnabled = enabled
        if (!enabled) {
            // Bypass mode: force-start camera if not running
            if (!isCameraRunning) {
                isCameraRunning = true
                cameraManager.start()
                overlay.setActive()
            }
        } else {
            // Restore mode: stop camera if sensors say we should be asleep
            if (!smartWake.isWakeState() && isCameraRunning) {
                isCameraRunning = false
                cameraManager.stop()
                overlay.setSleeping()
            }
        }
    }

    override fun onDestroy() {
        instance = null
        appMatcher.stop()
        smartWake.stop()
        if (isCameraRunning) cameraManager.stop()
        handTracker.close()
        overlay.dismiss()
        super.onDestroy()
    }

    /** Called from MainActivity to push profile mappings from Flutter/DB into the service. */
    fun loadProfileMappings(allProfiles: Map<String, Map<String, String>>) {
        profileCache.clear()
        profileCache.putAll(allProfiles)
        // Immediately apply for the current foreground app
        val defaultMappings = profileCache["__default__"] ?: emptyMap()
        actionDispatcher.setMappings(defaultMappings)
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
            .setSmallIcon(android.R.drawable.ic_menu_camera) // Replace with app icon
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
        } else {
            startForeground(1, notification)
        }
    }
}
