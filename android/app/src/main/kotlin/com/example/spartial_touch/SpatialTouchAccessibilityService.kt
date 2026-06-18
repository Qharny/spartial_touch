package com.example.spartial_touch

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class SpatialTouchAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("SpatialTouch", "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We do not need to process generic accessibility events for our use case right now,
        // but this method must be implemented.
    }

    override fun onInterrupt() {
        Log.d("SpatialTouch", "Accessibility Service Interrupted")
    }
}
