package com.example.spartial_touch

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult

class MediaPipeHandLandmarker(
    private val context: Context,
    private val onGestureDetected: (String) -> Unit
) {
    private var handLandmarker: HandLandmarker? = null

    // To prevent firing continuous gestures, we debounce.
    private var lastGestureTime = 0L
    private val debounceDelayMs = 1000L

    init {
        setupHandLandmarker()
    }

    private fun setupHandLandmarker() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")

        val optionsBuilder = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptionsBuilder.build())
            .setMinHandDetectionConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setNumHands(1)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener(this::returnLivestreamResult)
            .setErrorListener(this::returnLivestreamError)

        try {
            handLandmarker = HandLandmarker.createFromOptions(context, optionsBuilder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun detectLiveStream(image: Bitmap, imageRotation: Int) {
        if (handLandmarker == null) return

        val frameTime = SystemClock.uptimeMillis()
        val matrix = Matrix().apply {
            postRotate(imageRotation.toFloat())
            postScale(-1f, 1f, image.width / 2f, image.height / 2f)
        }
        val rotatedBitmap = Bitmap.createBitmap(image, 0, 0, image.width, image.height, matrix, true)
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        
        handLandmarker?.detectAsync(mpImage, frameTime)
    }

    private fun returnLivestreamResult(result: HandLandmarkerResult, input: MPImage) {
        if (result.landmarks().isEmpty()) return

        val currentTime = SystemClock.uptimeMillis()
        if (currentTime - lastGestureTime < debounceDelayMs) {
            return // Debounce
        }

        val landmarks = result.landmarks()[0]
        
        val wrist = landmarks[0]
        val indexTip = landmarks[8]
        val thumbTip = landmarks[4]

        val distance = Math.hypot((indexTip.x() - thumbTip.x()).toDouble(), (indexTip.y() - thumbTip.y()).toDouble())

        if (distance < 0.05) {
            lastGestureTime = currentTime
            onGestureDetected("Pinch")
        } else if (indexTip.y() < wrist.y() - 0.2) {
            lastGestureTime = currentTime
            onGestureDetected("Wave Up")
        }
    }

    private fun returnLivestreamError(error: RuntimeException) {
        error.printStackTrace()
    }
}
