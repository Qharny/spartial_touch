package kabuteyy.spartial_touch

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val GESTURE_CHANNEL = "kabuteyy.spartial_touch/gestures"
        const val GESTURE_EVENT_CHANNEL = "kabuteyy.spartial_touch/gesture_events"
        const val CAMERA_FRAME_CHANNEL = "kabuteyy.spartial_touch/camera_frames"
        const val LANDMARK_CHANNEL = "kabuteyy.spartial_touch/landmarks"
    }

    private val prefs by lazy { getSharedPreferences(GestureService.PREFS, MODE_PRIVATE) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up EventChannel for Gesture Events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    GestureEventBus.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    GestureEventBus.eventSink = null
                }
            }
        )

        // Set up EventChannel for Camera Frames
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CAMERA_FRAME_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CameraFrameEventBus.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    CameraFrameEventBus.eventSink = null
                }
            }
        )

        // Raw hand landmarks, only streamed while the custom-gesture recorder listens.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LANDMARK_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    LandmarkEventBus.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    LandmarkEventBus.eventSink = null
                }
            }
        )

        // Setup MethodChannel for GestureService control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        if (androidx.core.content.ContextCompat.checkSelfPermission(
                                this, android.Manifest.permission.CAMERA
                            ) != android.content.pm.PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error(
                                "PERMISSION_DENIED",
                                "CAMERA permission is not granted; cannot start the gesture service",
                                null
                            )
                        } else {
                            startGestureService()
                            result.success(null)
                        }
                    }
                    "stopService" -> {
                        stopGestureService()
                        result.success(null)
                    }
                    "performAction" -> {
                        val action = call.arguments as? String
                        if (action == null) {
                            result.error("INVALID_ARGUMENT", "Action argument is null", null)
                        } else if (ActionDispatcher.requiresAccessibility(action) &&
                            SpatialTouchAccessibilityService.instance == null
                        ) {
                            result.error(
                                "ACCESSIBILITY_NOT_ENABLED",
                                "SpatialTouch's Accessibility Service is not enabled in system settings",
                                null
                            )
                        } else if (ActionDispatcher(this).execute(action)) {
                            result.success(null)
                        } else {
                            result.error("UNKNOWN_ACTION", "Unknown action: $action", null)
                        }
                    }
                    "loadProfiles" -> {
                        // Argument: Map<packageName, Map<gestureKey, actionId>>
                        @Suppress("UNCHECKED_CAST")
                        val profiles = call.arguments as? Map<String, Map<String, String>>
                        if (profiles != null) {
                            GestureService.instance?.loadProfileMappings(profiles)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "Expected Map<String,Map<String,String>>", null)
                        }
                    }
                    "setPerformanceMode" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Int>
                        val fps = args?.get("fps") ?: 15
                        val cooldownMs = args?.get("cooldownMs") ?: 800
                        GestureInterpreter.applyCooldown(cooldownMs.toLong())
                        // Persist fps and cooldown for BackgroundCameraManager and GestureInterpreter to read on next start
                        prefs
                            .edit()
                            .putInt("detection_fps", fps)
                            .putLong("cooldown_ms", cooldownMs.toLong())
                            .apply()
                        result.success(null)
                    }
                    "setCalibration" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any>
                        val confidence = (args?.get("confidenceThreshold") as? Double)?.toFloat() ?: 0.75f
                        val motion = (args?.get("motionThreshold") as? Double)?.toFloat() ?: 0.12f
                        GestureInterpreter.applyCalibration(confidence, motion)
                        prefs
                            .edit()
                            .putFloat("confidence_threshold", confidence)
                            .putFloat("motion_threshold", motion)
                            .apply()
                        result.success(null)
                    }
                    "setHapticsEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: true
                        prefs
                            .edit().putBoolean("haptics_enabled", enabled).apply()
                        result.success(null)
                    }
                    "setSmartWakeEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: true
                        GestureService.instance?.setSmartWakeEnabled(enabled)
                        result.success(null)
                    }
                    "getServiceStats" -> {
                        val service = GestureService.instance

                        val totalGestures = prefs.getInt("total_gesture_count", 0)
                        
                        val activeProfile = if (service != null) {
                            service.getActiveProfileName()
                        } else {
                            "Standby"
                        }

                        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
                            .format(java.util.Date())
                        val todayGestures =
                            if (prefs.getString("today_date", null) == today) prefs.getInt("today_count", 0) else 0

                        val stats = mapOf(
                            "activeProfile" to activeProfile,
                            "totalGestures" to totalGestures,
                            "todayGestures" to todayGestures,
                            "pausedBySchedule" to (service?.isPausedBySchedule() ?: false)
                        )
                        result.success(stats)
                    }
                    "setGestureEnabled" -> {
                        val args = call.arguments as? Map<String, Any>
                        val key = args?.get("gestureKey") as? String
                        val enabled = args?.get("enabled") as? Boolean ?: true
                        if (key != null) {
                            prefs
                                .edit()
                                .putBoolean("gesture_enabled_$key", enabled)
                                .apply()
                        }
                        result.success(null)
                    }
                    "setServiceEnabled" -> {
                        // The user's on/off intent — read by BootReceiver after a restart.
                        prefs.edit().putBoolean("service_enabled", call.arguments as? Boolean ?: false).apply()
                        result.success(null)
                    }
                    "isServiceRunning" -> {
                        result.success(GestureService.instance != null)
                    }
                    "setOverlaySettings" -> {
                        val args = call.arguments as? Map<*, *>
                        prefs.edit()
                            .putBoolean("overlay_enabled", args?.get("enabled") as? Boolean ?: true)
                            .putFloat("overlay_opacity", ((args?.get("opacity") as? Number)?.toFloat() ?: 0.8f))
                            .apply()
                        GestureService.instance?.applyOverlaySettings()
                        result.success(null)
                    }
                    "setSoundsEnabled" -> {
                        prefs.edit().putBoolean("sounds_enabled", call.arguments as? Boolean ?: false).apply()
                        result.success(null)
                    }
                    "setPauseInDnd" -> {
                        prefs.edit().putBoolean("pause_in_dnd", call.arguments as? Boolean ?: true).apply()
                        result.success(null)
                    }
                    "setSmartWakePreference" -> {
                        // The user setting (battery saver), distinct from setSmartWakeEnabled,
                        // which testing screens use to force the camera on temporarily.
                        prefs.edit().putBoolean("smart_wake_enabled", call.arguments as? Boolean ?: true).apply()
                        GestureService.instance?.refreshSchedule()
                        result.success(null)
                    }
                    "setActiveHours" -> {
                        val args = call.arguments as? Map<*, *>
                        prefs.edit()
                            .putBoolean("active_hours_enabled", args?.get("enabled") as? Boolean ?: false)
                            .putInt("active_hours_start", (args?.get("startMinutes") as? Number)?.toInt() ?: 8 * 60)
                            .putInt("active_hours_end", (args?.get("endMinutes") as? Number)?.toInt() ?: 22 * 60)
                            .apply()
                        GestureService.instance?.refreshSchedule()
                        result.success(null)
                    }
                    "setGestureSensitivity" -> {
                        val args = call.arguments as? Map<*, *>
                        val key = args?.get("gestureKey") as? String
                        val value = (args?.get("value") as? Number)?.toFloat()
                        if (key == null || value == null) {
                            result.error("INVALID_ARGUMENT", "Expected {gestureKey, value}", null)
                        } else {
                            prefs.edit().putFloat("gesture_sensitivity_$key", value).apply()
                            GestureInterpreter.applySensitivity(key, value)
                            result.success(null)
                        }
                    }
                    "setCustomPoses" -> {
                        // Argument: {"json": "[{key, samples}]", "names": {key: displayName}}
                        val args = call.arguments as? Map<*, *>
                        val json = args?.get("json") as? String ?: "[]"
                        val names = args?.get("names") as? Map<*, *> ?: emptyMap<String, String>()
                        val editor = prefs.edit().putString("custom_poses_json", json)
                        prefs.all.keys.filter { it.startsWith("gesture_name_") }.forEach { editor.remove(it) }
                        names.forEach { (k, v) -> if (k is String && v is String) editor.putString("gesture_name_$k", v) }
                        editor.apply()
                        CustomPoseMatcher.setPoses(CustomPoseMatcher.parse(json))
                        result.success(null)
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(SpatialTouchAccessibilityService.instance != null)
                    }
                    "hasUsageAccess" -> {
                        result.success(hasUsageAccess())
                    }
                    "openUsageAccessSettings" -> {
                        startActivity(
                            Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Whether the "Usage access" special permission is granted. ForegroundAppMatcher relies on
     * UsageStatsManager, which silently returns nothing without it — per-app gesture
     * assignments would save but never trigger.
     */
    @Suppress("DEPRECATION")
    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(android.content.Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName
            )
        } else {
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun startGestureService() {
        val intent = Intent(this, GestureService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopGestureService() {
        val intent = Intent(this, GestureService::class.java)
        stopService(intent)
    }
}
