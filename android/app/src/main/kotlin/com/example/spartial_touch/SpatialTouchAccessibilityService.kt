package com.example.spartial_touch

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.content.Intent

class SpatialTouchAccessibilityService : AccessibilityService() {

    companion object {
        var instance: SpatialTouchAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("SpatialTouch", "Accessibility Service Connected")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.d("SpatialTouch", "Accessibility Service Unbound")
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for injecting gestures
    }

    override fun onInterrupt() {
        Log.d("SpatialTouch", "Accessibility Service Interrupted")
    }

    fun dispatchTouchGesture(action: String) {
        val displayMetrics = resources.displayMetrics
        val width = displayMetrics.widthPixels.toFloat()
        val height = displayMetrics.heightPixels.toFloat()

        val centerX = width / 2
        val centerY = height / 2

        val path = Path()

        when (action) {
            "scroll_up" -> {
                path.moveTo(centerX, centerY - 200)
                path.lineTo(centerX, centerY + 400)
            }
            "scroll_down" -> {
                path.moveTo(centerX, centerY + 200)
                path.lineTo(centerX, centerY - 400)
            }
            "swipe_left" -> {
                path.moveTo(centerX + 300, centerY)
                path.lineTo(centerX - 300, centerY)
            }
            "swipe_right" -> {
                path.moveTo(centerX - 300, centerY)
                path.lineTo(centerX + 300, centerY)
            }
            "tap" -> {
                path.moveTo(centerX, centerY)
            }
            else -> {
                Log.w("SpatialTouch", "Unknown touch action: $action")
                return
            }
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, 300)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        dispatchGesture(gesture, null, null)
    }

    fun performSystemAction(action: String) {
        when (action) {
            "back" -> performGlobalAction(GLOBAL_ACTION_BACK)
            "home" -> performGlobalAction(GLOBAL_ACTION_HOME)
            "recents" -> performGlobalAction(GLOBAL_ACTION_RECENTS)
            else -> Log.w("SpatialTouch", "Unknown system action: $action")
        }
    }
}
