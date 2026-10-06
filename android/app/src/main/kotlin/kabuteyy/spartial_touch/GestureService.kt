package kabuteyy.spartial_touch

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
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

object LandmarkEventBus {
    @Volatile var eventSink: EventChannel.EventSink? = null

    fun hasListener(): Boolean = eventSink != null

    /** Sends `[x0, y0, …, x20, y20, confidence]` — 43 doubles — to Flutter. */
    fun sendLandmarks(points: FloatArray, confidence: Float) {
        val payload = ArrayList<Double>(points.size + 1)
        points.forEach { payload.add(it.toDouble()) }
        payload.add(confidence.toDouble())
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(payload)
        }
    }
}

class GestureService : Service() {
    private lateinit var prefs: SharedPreferences
    private lateinit var handTracker: HandTracker
    private lateinit var cameraManager: BackgroundCameraManager
    private lateinit var smartWake: SmartWakeManager
    private lateinit var overlay: OverlayManager
    private lateinit var appMatcher: ForegroundAppMatcher
    val actionDispatcher by lazy { ActionDispatcher(this) }

    private val mainHandler = Handler(Looper.getMainLooper())

    // Camera state. Everything below is only touched on the main thread, and every change
    // goes through updateCamera(), so there is exactly one place that decides on/off.
    private var isCameraRunning = false
    /** False while a Flutter screen (tester, recorder, gesture detail) needs the camera on. */
    private var isSmartWakeEnabled = true
    /** SmartWake keeps the camera on until this uptime (ms) — extended whenever a hand is seen. */
    private var wakeUntil = 0L
    private var pausedBySchedule = false

    // Frame-rate limit from the performance preset. Read on the camera analysis thread.
    @Volatile private var lastFrameMs = 0L
    @Volatile private var lastHandSeenMs = 0L

    private var toneGenerator: ToneGenerator? = null

    private val profileCache = mutableMapOf<String, Map<String, String>>()
    private var activeProfilePackage = "__default__"

    companion object {
        var instance: GestureService? = null
            private set

        const val PREFS = "spatialtouch_prefs"
        /** How long SmartWake keeps the camera on after the last wake trigger or visible hand. */
        private const val WAKE_WINDOW_MS = 10_000L
        private const val TICK_MS = 2_000L
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "gesture_service_channel"
    }

    // Periodic housekeeping: SmartWake timeout and active-hours window.
    private val tick = object : Runnable {
        override fun run() {
            applyActiveHours()
            updateCamera()
            mainHandler.postDelayed(this, TICK_MS)
        }
    }

    fun getActiveProfileName(): String {
        val pkg = activeProfilePackage
        // An app with no profile of its own runs on the default assignments — report that.
        if (pkg == "__default__" || !profileCache.containsKey(pkg)) return "Default"
        return try {
            val pm = packageManager
            val info = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            pkg.substringAfterLast('.')
                .replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
        }
    }

    fun isPausedBySchedule(): Boolean = pausedBySchedule

    override fun onCreate() {
        super.onCreate()
        instance = this

        // A camera-typed foreground service requires CAMERA to already be granted on
        // Android 14+ (targetSdk 34) — starting without it throws a SecurityException
        // that would otherwise crash the whole app process. Bail out cleanly instead.
        if (androidx.core.content.ContextCompat.checkSelfPermission(
                this, android.Manifest.permission.CAMERA
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            Log.e("GestureService", "CAMERA permission not granted — stopping service")
            instance = null
            stopSelf()
            return
        }

        if (!startForegroundNotification()) {
            instance = null
            stopSelf()
            return
        }

        prefs = getSharedPreferences(PREFS, MODE_PRIVATE)

        // Load persisted calibration, performance, sensitivity and custom-pose settings
        GestureInterpreter.applyCalibration(
            prefs.getFloat("confidence_threshold", 0.75f),
            prefs.getFloat("motion_threshold", 0.12f)
        )
        GestureInterpreter.applyCooldown(prefs.getLong("cooldown_ms", 800L))
        for ((key, value) in prefs.all) {
            if (key.startsWith("gesture_sensitivity_") && value is Float) {
                GestureInterpreter.applySensitivity(key.removePrefix("gesture_sensitivity_"), value)
            }
        }
        CustomPoseMatcher.setPoses(CustomPoseMatcher.parse(prefs.getString("custom_poses_json", "[]") ?: "[]"))

        // Floating overlay — shows engine status over other apps
        overlay = OverlayManager(this)
        overlay.setOpacity(prefs.getFloat("overlay_opacity", 0.8f))
        if (prefs.getBoolean("overlay_enabled", true)) {
            overlay.show()
            overlay.setSleeping()
        }

        // Hand tracker — calls back with "GESTURE:confidence" payload
        handTracker = HandTracker(
            this,
            onGestureDetected = { payload -> onGesture(payload) },
            onHandSeen = { lastHandSeenMs = SystemClock.uptimeMillis() }
        )
        handTracker.init()

        // Camera — frames are dropped down to the performance preset's FPS before inference.
        cameraManager = BackgroundCameraManager(this) { bitmap, bytes, timestamp ->
            val fps = prefs.getInt("detection_fps", 15).coerceIn(1, 60)
            if (timestamp - lastFrameMs >= 1000L / fps) {
                lastFrameMs = timestamp
                handTracker.processFrame(bitmap, timestamp)
                CameraFrameEventBus.sendFrame(bytes)
            }
        }

        // ForegroundAppMatcher — auto-switch profiles when app changes
        appMatcher = ForegroundAppMatcher(this) { packageName ->
            activeProfilePackage = packageName
            applyMappingsFor(packageName)
            Log.d("GestureService", "Profile switched → $packageName")
        }
        appMatcher.start()

        // SmartWake — a hand near the proximity sensor opens a wake window; the window then
        // stays open for as long as the camera keeps seeing a hand. It used to stop the camera
        // the moment the proximity sensor read FAR again, i.e. as soon as the hand moved back
        // to a normal gesturing distance, so gestures only worked ~5cm from the sensor.
        smartWake = SmartWakeManager(
            context = this,
            onWake = {
                wakeUntil = SystemClock.uptimeMillis() + WAKE_WINDOW_MS
                updateCamera()
            },
            onSleep = { /* the wake window times out on its own in updateCamera() */ }
        )
        smartWake.start()

        applyActiveHours()
        updateCamera()
        mainHandler.postDelayed(tick, TICK_MS)
    }

    /** Runs on MediaPipe's result-listener thread for every recognised gesture. */
    private fun onGesture(gesturePayload: String) {
        val rawKey = gesturePayload.substringBefore(':')
        // While a Flutter screen is testing, every gesture is reported (but still only
        // dispatched if enabled) so the user can see what the engine recognises.
        val testing = !isSmartWakeEnabled
        val isEnabled = prefs.getBoolean("gesture_enabled_$rawKey", true)
        if (!isEnabled && !testing) return
        if (!testing && isDoNotDisturbActive()) return

        countGesture()
        GestureEventBus.sendEvent(gesturePayload)
        if (isEnabled) actionDispatcher.dispatch(gesturePayload)

        if (prefs.getBoolean("haptics_enabled", true)) HapticService.pulse(this, "medium")
        if (prefs.getBoolean("sounds_enabled", false)) playClick()
        overlay.flashGesture(displayName(rawKey))
    }

    /** Custom poses report their user-given name; built-ins become "Wave Up" etc. */
    private fun displayName(rawKey: String): String =
        prefs.getString("gesture_name_$rawKey", null)
            ?: rawKey.split('_').joinToString(" ") { it.lowercase().replaceFirstChar(Char::uppercaseChar) }

    private fun countGesture() {
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
        val todayCount = if (prefs.getString("today_date", null) == today) prefs.getInt("today_count", 0) else 0
        prefs.edit()
            .putInt("total_gesture_count", prefs.getInt("total_gesture_count", 0) + 1)
            .putString("today_date", today)
            .putInt("today_count", todayCount + 1)
            .apply()
    }

    private fun playClick() {
        try {
            val tone = toneGenerator ?: ToneGenerator(AudioManager.STREAM_NOTIFICATION, 60).also {
                toneGenerator = it
            }
            tone.startTone(ToneGenerator.TONE_PROP_BEEP, 60)
        } catch (e: Exception) {
            // ToneGenerator can fail to initialise on some devices (no audio route); not fatal.
            Log.w("GestureService", "Click sound unavailable", e)
        }
    }

    /** True when "Pause during Do Not Disturb" is on and the system is in a DND mode. */
    private fun isDoNotDisturbActive(): Boolean {
        if (!prefs.getBoolean("pause_in_dnd", true)) return false
        val nm = getSystemService(NotificationManager::class.java) ?: return false
        val filter = nm.currentInterruptionFilter
        return filter != NotificationManager.INTERRUPTION_FILTER_ALL &&
            filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
    }

    /** Enables or disables smart wake gating dynamically (e.g. while a testing screen is open). */
    fun setSmartWakeEnabled(enabled: Boolean) {
        isSmartWakeEnabled = enabled
        if (enabled) wakeUntil = SystemClock.uptimeMillis() + WAKE_WINDOW_MS
        updateCamera()
    }

    /** Re-reads the overlay settings and applies them immediately. */
    fun applyOverlaySettings() {
        overlay.setOpacity(prefs.getFloat("overlay_opacity", 0.8f))
        if (prefs.getBoolean("overlay_enabled", true)) {
            overlay.show()
            if (isCameraRunning) overlay.setActive() else overlay.setSleeping()
        } else {
            overlay.dismiss()
        }
    }

    /** Re-evaluates the active-hours window now (called after the user changes it). */
    fun refreshSchedule() {
        applyActiveHours()
        updateCamera()
    }

    private fun applyActiveHours() {
        val enabled = prefs.getBoolean("active_hours_enabled", false)
        val paused = enabled && !ActiveHours.isInWindow(
            java.util.Calendar.getInstance(),
            prefs.getInt("active_hours_start", 8 * 60),
            prefs.getInt("active_hours_end", 22 * 60)
        )
        if (paused != pausedBySchedule) {
            pausedBySchedule = paused
            updateNotification()
        }
    }

    /** The one place that turns the camera on or off. Main thread only. */
    private fun updateCamera() {
        if (!::cameraManager.isInitialized) return
        val now = SystemClock.uptimeMillis()
        if (now - lastHandSeenMs < TICK_MS) wakeUntil = maxOf(wakeUntil, now + WAKE_WINDOW_MS)

        val smartWakeOn = prefs.getBoolean("smart_wake_enabled", true) &&
            ::smartWake.isInitialized && smartWake.hasProximitySensor()
        val wanted = when {
            !isSmartWakeEnabled -> true          // a testing screen needs the camera
            pausedBySchedule -> false
            !smartWakeOn -> true
            else -> now < wakeUntil
        }
        if (wanted == isCameraRunning) return
        isCameraRunning = wanted
        if (wanted) {
            cameraManager.start()
            overlay.setActive()
        } else {
            cameraManager.stop()
            overlay.setSleeping()
        }
    }

    override fun onDestroy() {
        instance = null
        mainHandler.removeCallbacksAndMessages(null)
        // onCreate() can bail out (missing permission, startForeground failure) before
        // these are assigned — guard each so the early stopSelf() path doesn't crash here.
        if (::appMatcher.isInitialized) appMatcher.stop()
        if (::smartWake.isInitialized) smartWake.stop()
        if (::cameraManager.isInitialized) cameraManager.release()
        if (::handTracker.isInitialized) handTracker.close()
        if (::overlay.isInitialized) overlay.dismiss()
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    /** Called from MainActivity to push profile mappings from Flutter/DB into the service. */
    fun loadProfileMappings(allProfiles: Map<String, Map<String, String>>) {
        profileCache.clear()
        profileCache.putAll(allProfiles)
        // Re-resolve for whatever app is currently in front. This used to always apply the
        // default profile, so saving an assignment had no effect on the foreground app's
        // own overrides until the user switched apps and back.
        applyMappingsFor(activeProfilePackage)
    }

    /**
     * Resolves the effective gesture → action map for [packageName]: the global (default)
     * assignments, with that app's own assignments layered on top. An app profile therefore
     * only needs to list the gestures it *overrides* — everything else keeps its global action
     * instead of silently doing nothing.
     */
    private fun applyMappingsFor(packageName: String) {
        val merged = HashMap<String, String>()
        profileCache["__default__"]?.let { merged.putAll(it) }
        if (packageName != "__default__") {
            profileCache[packageName]?.let { merged.putAll(it) }
        }
        actionDispatcher.setMappings(merged)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // Not a bound service
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        val text = if (pausedBySchedule) "Paused outside your active hours" else "Listening for hand gestures"
        val openApp = android.app.PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            android.app.PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SpatialTouch")
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openApp)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification() {
        try {
            getSystemService(NotificationManager::class.java)?.notify(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            Log.w("GestureService", "Could not update notification", e)
        }
    }

    /** Returns false if the foreground start failed and the service should stop itself. */
    private fun startForegroundNotification(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Gesture Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, buildNotification(), android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
            } else {
                startForeground(NOTIFICATION_ID, buildNotification())
            }
            true
        } catch (e: Exception) {
            // e.g. SecurityException if a permission was revoked between the check above
            // and this call, or ForegroundServiceStartNotAllowedException on some OEMs.
            Log.e("GestureService", "startForeground failed", e)
            false
        }
    }
}
