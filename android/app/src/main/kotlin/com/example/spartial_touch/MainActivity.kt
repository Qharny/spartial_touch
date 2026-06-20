package com.example.spartial_touch

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val GESTURE_CHANNEL = "com.example.spartial_touch/gestures"
        const val GESTURE_EVENT_CHANNEL = "com.example.spartial_touch/gesture_events"
        const val CAMERA_FRAME_CHANNEL = "com.example.spartial_touch/camera_frames"
        const val VOLUME_CHANNEL = "com.example.spartial_touch/volume"
    }

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

        // Setup MethodChannel for GestureService control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        startGestureService()
                        result.success(null)
                    }
                    "stopService" -> {
                        stopGestureService()
                        result.success(null)
                    }
                    "performAction" -> {
                        val action = call.arguments as? String
                        if (action != null) {
                            if (action in listOf("back", "home", "recents")) {
                                SpatialTouchAccessibilityService.instance?.performSystemAction(action)
                            } else {
                                SpatialTouchAccessibilityService.instance?.dispatchTouchGesture(action)
                            }
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "Action argument is null", null)
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
                        getSharedPreferences("spatialtouch_prefs", MODE_PRIVATE)
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
                        getSharedPreferences("spatialtouch_prefs", MODE_PRIVATE)
                            .edit()
                            .putFloat("confidence_threshold", confidence)
                            .putFloat("motion_threshold", motion)
                            .apply()
                        result.success(null)
                    }
                    "setHapticsEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: true
                        getSharedPreferences("spatialtouch_prefs", MODE_PRIVATE)
                            .edit().putBoolean("haptics_enabled", enabled).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Set up MethodChannel for Volume Control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(android.content.Context.AUDIO_SERVICE) as android.media.AudioManager
            if (call.method == "volumeUp") {
                audioManager.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_RAISE, android.media.AudioManager.FLAG_SHOW_UI)
                result.success(null)
            } else if (call.method == "volumeDown") {
                audioManager.adjustStreamVolume(android.media.AudioManager.STREAM_MUSIC, android.media.AudioManager.ADJUST_LOWER, android.media.AudioManager.FLAG_SHOW_UI)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
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
