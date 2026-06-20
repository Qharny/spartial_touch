package com.example.spartial_touch

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark

object GestureInterpreter {

    // MediaPipe hand landmark indices
    private const val WRIST = 0
    private const val THUMB_TIP = 4
    private const val THUMB_IP = 3
    private const val INDEX_TIP = 8
    private const val INDEX_MCP = 5
    private const val MIDDLE_TIP = 12
    private const val MIDDLE_MCP = 9
    private const val RING_TIP = 16
    private const val RING_MCP = 13
    private const val PINKY_TIP = 20
    private const val PINKY_MCP = 17

    // Motion history for wave gestures
    private val wristHistory = ArrayDeque<Pair<Float, Float>>()
    private val indexHistory = ArrayDeque<Pair<Float, Float>>()  // for fist pump (Z-axis proxy)
    private const val HISTORY_SIZE = 8
    private var lastGestureTime = 0L
    private var cooldownMs = 800L         // mutable; updated by applyCooldown()
    private var minConfidence = 0.75f     // mutable; updated by applyCalibration()
    private var motionThreshold = 0.12f   // mutable; updated by applyCalibration()

    /** Called from MainActivity when the user changes performance mode. */
    fun applyCooldown(ms: Long) { cooldownMs = ms }

    /** Called from MainActivity when calibration values are saved. */
    fun applyCalibration(confidenceThreshold: Float, motionThresholdValue: Float) {
        minConfidence   = confidenceThreshold
        motionThreshold = motionThresholdValue
    }

    // Hold gesture tracking (Open Palm Hold)
    private var openPalmStartTime = 0L
    private const val HOLD_DURATION_MS = 1200L

    fun interpret(landmarks: List<NormalizedLandmark>, confidence: Float): String? {
        val now = System.currentTimeMillis()
        if (now - lastGestureTime < cooldownMs) return null
        if (confidence < minConfidence) return null

        val wrist = landmarks[WRIST]

        // Update wrist motion history
        wristHistory.addLast(Pair(wrist.x(), wrist.y()))
        if (wristHistory.size > HISTORY_SIZE) wristHistory.removeFirst()

        // Track index tip size as a Z-proxy for fist pump
        val indexSize = distance(landmarks[WRIST], landmarks[INDEX_TIP])
        indexHistory.addLast(Pair(indexSize, 0f))
        if (indexHistory.size > HISTORY_SIZE) indexHistory.removeFirst()

        // --- Static / Hold Gestures (checked before motion to avoid false-motion triggers) ---

        // Open Palm Hold: all 4 fingers extended + held for HOLD_DURATION_MS
        if (isOpenPalm(landmarks)) {
            if (openPalmStartTime == 0L) openPalmStartTime = now
            if (now - openPalmStartTime >= HOLD_DURATION_MS) {
                openPalmStartTime = 0L
                return fire("OPEN_PALM_HOLD", confidence)
            }
        } else {
            openPalmStartTime = 0L
        }

        // Need full history for motion gestures
        if (wristHistory.size < HISTORY_SIZE) return null

        val deltaX = wristHistory.last().first - wristHistory.first().first
        val deltaY = wristHistory.last().second - wristHistory.first().second

        // --- Motion Gestures ---

        val gesture = when {
            // Wave directions
            deltaY < -motionThreshold && Math.abs(deltaY) > Math.abs(deltaX) * 1.5f -> "WAVE_UP"
            deltaY >  motionThreshold && Math.abs(deltaY) > Math.abs(deltaX) * 1.5f -> "WAVE_DOWN"
            deltaX < -motionThreshold && Math.abs(deltaX) > Math.abs(deltaY) * 1.5f -> "WAVE_LEFT"
            deltaX >  motionThreshold && Math.abs(deltaX) > Math.abs(deltaY) * 1.5f -> "WAVE_RIGHT"

            // Fist pump: wrist size (index-to-wrist dist) rapidly increases = hand punching forward
            isFistPump() -> "FIST_PUMP"

            // Two-finger swipes (must be detected before single-finger)
            isTwoFingerExtended(landmarks) && deltaX > motionThreshold  -> "TWO_FINGER_SWIPE_RIGHT"
            isTwoFingerExtended(landmarks) && deltaX < -motionThreshold -> "TWO_FINGER_SWIPE_LEFT"

            // Static poses
            isPinch(landmarks)       -> "PINCH"
            isThumbsUp(landmarks)    -> "THUMBS_UP"
            isThumbsDown(landmarks)  -> "THUMBS_DOWN"
            isIndexPointUp(landmarks)-> "INDEX_POINT_UP"
            isRockSign(landmarks)    -> "ROCK_SIGN"

            else -> null
        }

        if (gesture != null) {
            wristHistory.clear()
            indexHistory.clear()
            return fire(gesture, confidence)
        }

        return null
    }

    private fun fire(gesture: String, confidence: Float): String {
        lastGestureTime = System.currentTimeMillis()
        return "$gesture:${String.format("%.4f", confidence)}"
    }

    // ── Pose detectors ──────────────────────────────────────────────────────────

    private fun isPinch(lm: List<NormalizedLandmark>): Boolean =
        distance(lm[THUMB_TIP], lm[INDEX_TIP]) < 0.05f

    private fun isOpenPalm(lm: List<NormalizedLandmark>): Boolean =
        lm[INDEX_TIP].y()  < lm[INDEX_MCP].y()  &&
        lm[MIDDLE_TIP].y() < lm[MIDDLE_MCP].y() &&
        lm[RING_TIP].y()   < lm[RING_MCP].y()   &&
        lm[PINKY_TIP].y()  < lm[PINKY_MCP].y()

    private fun isThumbsUp(lm: List<NormalizedLandmark>): Boolean =
        lm[THUMB_TIP].y() < lm[WRIST].y() - 0.1f &&
        lm[INDEX_TIP].y() > lm[INDEX_MCP].y()      &&
        lm[MIDDLE_TIP].y() > lm[MIDDLE_MCP].y()    &&
        lm[RING_TIP].y()   > lm[RING_MCP].y()      &&
        lm[PINKY_TIP].y()  > lm[PINKY_MCP].y()

    private fun isThumbsDown(lm: List<NormalizedLandmark>): Boolean =
        lm[THUMB_TIP].y() > lm[WRIST].y() + 0.1f &&
        lm[INDEX_TIP].y() > lm[INDEX_MCP].y()      &&
        lm[MIDDLE_TIP].y() > lm[MIDDLE_MCP].y()

    private fun isIndexPointUp(lm: List<NormalizedLandmark>): Boolean =
        lm[INDEX_TIP].y() < lm[INDEX_MCP].y() - 0.15f &&
        lm[MIDDLE_TIP].y() > lm[MIDDLE_MCP].y()        &&
        lm[RING_TIP].y()   > lm[RING_MCP].y()          &&
        lm[PINKY_TIP].y()  > lm[PINKY_MCP].y()

    private fun isTwoFingerExtended(lm: List<NormalizedLandmark>): Boolean =
        lm[INDEX_TIP].y()  < lm[INDEX_MCP].y()  &&
        lm[MIDDLE_TIP].y() < lm[MIDDLE_MCP].y() &&
        lm[RING_TIP].y()   > lm[RING_MCP].y()   &&
        lm[PINKY_TIP].y()  > lm[PINKY_MCP].y()

    private fun isRockSign(lm: List<NormalizedLandmark>): Boolean =
        lm[INDEX_TIP].y()  < lm[INDEX_MCP].y()  &&   // index extended
        lm[PINKY_TIP].y()  < lm[PINKY_MCP].y()  &&   // pinky extended
        lm[MIDDLE_TIP].y() > lm[MIDDLE_MCP].y() &&   // middle curled
        lm[RING_TIP].y()   > lm[RING_MCP].y()         // ring curled

    private fun isFistPump(): Boolean {
        if (indexHistory.size < HISTORY_SIZE) return false
        val recent = indexHistory.takeLast(4).map { it.first }.average().toFloat()
        val older  = indexHistory.take(4).map { it.first }.average().toFloat()
        // Hand approaching camera = apparent size grows (index-wrist distance grows)
        return recent > older * 1.4f
    }

    private fun distance(a: NormalizedLandmark, b: NormalizedLandmark): Float {
        val dx = a.x() - b.x()
        val dy = a.y() - b.y()
        return Math.sqrt((dx * dx + dy * dy).toDouble()).toFloat()
    }
}
