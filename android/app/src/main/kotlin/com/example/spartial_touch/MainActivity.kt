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
