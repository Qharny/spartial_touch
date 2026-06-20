package com.example.spartial_touch

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult

class HandTracker(
    private val context: Context,
    private val onGestureDetected: (String) -> Unit
) {
    private var handLandmarker: HandLandmarker? = null

    fun init() {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .setDelegate(com.google.mediapipe.tasks.core.Delegate.GPU) // falls back to CPU automatically
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumHands(1)
            .setMinHandDetectionConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setResultListener { result, _ -> processResult(result) }
            .build()

        handLandmarker = HandLandmarker.createFromOptions(context, options)
    }

    fun processFrame(bitmap: Bitmap, timestampMs: Long) {
        if (handLandmarker == null) return
        val mpImage = BitmapImageBuilder(bitmap).build()
        try {
            handLandmarker?.detectAsync(mpImage, timestampMs)
        } catch (e: Exception) {
            // Ignored, occurs if task graph is closed concurrently
        }
    }

    private fun processResult(result: HandLandmarkerResult) {
        if (result.landmarks().isEmpty()) return

        val landmarks = result.landmarks()[0] // first hand

        // Extract the hand presence confidence from MediaPipe result
        val confidence: Float = if (result.handedness().isNotEmpty() &&
            result.handedness()[0].isNotEmpty()) {
            result.handedness()[0][0].score()
        } else {
            0f
        }

        val gesture = GestureInterpreter.interpret(landmarks, confidence)

        if (gesture != null) {
            onGestureDetected(gesture)
        }
    }

    fun close() {
        try {
            handLandmarker?.close()
        } catch (e: Exception) {
            // Ignored
        } finally {
            handLandmarker = null
        }
    }
}
