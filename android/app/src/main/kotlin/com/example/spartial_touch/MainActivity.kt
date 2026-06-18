package com.example.spartial_touch

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import androidx.lifecycle.LifecycleOwner

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.spartial_touch/gestures"
    private var eventSink: EventChannel.EventSink? = null
    
    private lateinit var cameraManager: CameraManager
    private lateinit var mediaPipeHandLandmarker: MediaPipeHandLandmarker

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up EventChannel for Gestures
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startGestureRecognition()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopGestureRecognition()
                }
            }
        )

        // Set up MethodChannel for Volume Control
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.spartial_touch/volume").setMethodCallHandler { call, result ->
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

    private fun startGestureRecognition() {
        mediaPipeHandLandmarker = MediaPipeHandLandmarker(this) { gesture ->
            runOnUiThread {
                eventSink?.success(gesture)
            }
        }
        
        // Activity implements LifecycleOwner directly in AndroidX component frameworks.
        cameraManager = CameraManager(this, this as LifecycleOwner) { bitmap, rotation ->
            mediaPipeHandLandmarker.detectLiveStream(bitmap, rotation)
        }
        cameraManager.startCamera()
    }

    private fun stopGestureRecognition() {
        if (::cameraManager.isInitialized) {
            cameraManager.stopCamera()
        }
    }
}
