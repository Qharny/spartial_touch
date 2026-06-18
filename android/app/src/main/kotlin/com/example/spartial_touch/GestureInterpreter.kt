package com.example.spartial_touch

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark

object GestureInterpreter {

    // MediaPipe hand landmark indices
    private const val WRIST = 0
    private const val THUMB_TIP = 4
    private const val INDEX_TIP = 8
    private const val MIDDLE_TIP = 12
    private const val RING_TIP = 16
    private const val PINKY_TIP = 20
    private const val INDEX_MCP = 5  // knuckle base

    // History for motion gestures (wave up/down/left/right)
    private val wristHistory = ArrayDeque<Pair<Float, Float>>() // (x, y)
    private const val HISTORY_SIZE = 8
    private var lastGestureTime = 0L
    private const val COOLDOWN_MS = 800L

    fun interpret(landmarks: List<NormalizedLandmark>): String? {
        val now = System.currentTimeMillis()
        if (now - lastGestureTime < COOLDOWN_MS) return null

        val wrist = landmarks[WRIST]
        val indexTip = landmarks[INDEX_TIP]
        val thumbTip = landmarks[THUMB_TIP]

        // Update motion history
        wristHistory.addLast(Pair(wrist.x(), wrist.y()))
        if (wristHistory.size > HISTORY_SIZE) wristHistory.removeFirst()
        if (wristHistory.size < HISTORY_SIZE) return null

        val deltaX = wristHistory.last().first - wristHistory.first().first
        val deltaY = wristHistory.last().second - wristHistory.first().second
        val motionThreshold = 0.12f

        // Motion gestures (wave)
        val gesture = when {
            deltaY < -motionThreshold && Math.abs(deltaY) > Math.abs(deltaX) * 1.5f -> "WAVE_UP"
            deltaY >  motionThreshold && Math.abs(deltaY) > Math.abs(deltaX) * 1.5f -> "WAVE_DOWN"
            deltaX < -motionThreshold && Math.abs(deltaX) > Math.abs(deltaY) * 1.5f -> "WAVE_LEFT"
            deltaX >  motionThreshold && Math.abs(deltaX) > Math.abs(deltaY) * 1.5f -> "WAVE_RIGHT"
            isPinch(landmarks)    -> "PINCH"
            isOpenPalm(landmarks) -> "OPEN_PALM"
            isThumbsUp(landmarks) -> "THUMBS_UP"
            else -> null
        }

        if (gesture != null) {
            lastGestureTime = now
            wristHistory.clear()
        }

        return gesture
    }

    private fun isPinch(lm: List<NormalizedLandmark>): Boolean {
        val dist = distance(lm[THUMB_TIP], lm[INDEX_TIP])
        return dist < 0.05f
    }

    private fun isOpenPalm(lm: List<NormalizedLandmark>): Boolean {
        // All fingertips above their MCP (knuckle) = open palm
        return lm[INDEX_TIP].y() < lm[INDEX_MCP].y() &&
               lm[MIDDLE_TIP].y() < lm[9].y() &&
               lm[RING_TIP].y() < lm[13].y() &&
               lm[PINKY_TIP].y() < lm[17].y()
    }

    private fun isThumbsUp(lm: List<NormalizedLandmark>): Boolean {
        // Thumb tip above wrist, all other fingers curled
        return lm[THUMB_TIP].y() < lm[WRIST].y() - 0.1f &&
               lm[INDEX_TIP].y() > lm[INDEX_MCP].y() &&
               lm[MIDDLE_TIP].y() > lm[9].y()
    }

    private fun distance(a: NormalizedLandmark, b: NormalizedLandmark): Float {
        val dx = a.x() - b.x()
        val dy = a.y() - b.y()
        return Math.sqrt((dx * dx + dy * dy).toDouble()).toFloat()
    }
}
