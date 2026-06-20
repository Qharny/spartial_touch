package com.example.spartial_touch

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * OverlayManager draws a draggable floating status bubble using SYSTEM_ALERT_WINDOW.
 * It shows a small indicator when the gesture engine is active, and flashes green
 * when a gesture is successfully recognized.
 */
class OverlayManager(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())
    private var overlayView: View? = null
    private var statusDot: View? = null
    private var statusLabel: TextView? = null

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    fun show() {
        if (!canDrawOverlay()) {
            Log.w("OverlayManager", "SYSTEM_ALERT_WINDOW permission not granted")
            return
        }
        if (overlayView != null) return

        handler.post {
            buildOverlay()
        }
    }

    fun dismiss() {
        handler.post {
            overlayView?.let {
                try {
                    windowManager.removeView(it)
                } catch (e: Exception) {
                    Log.e("OverlayManager", "Error removing overlay", e)
                }
                overlayView = null
                statusDot = null
                statusLabel = null
            }
        }
    }

    /**
     * Flash the overlay green to signal a recognized gesture, then revert.
     * @param gestureName The human-readable gesture name to display briefly.
     */
    fun flashGesture(gestureName: String) {
        handler.post {
            statusDot?.setBackgroundColor(Color.parseColor("#00E676")) // green flash
            statusLabel?.text = gestureName
            handler.postDelayed({
                statusDot?.setBackgroundColor(Color.parseColor("#7C4DFF")) // revert to purple
                statusLabel?.text = "Listening"
            }, 800)
        }
    }

    /** Set the dot to a sleeping/idle state (grey) */
    fun setSleeping() {
        handler.post {
            statusDot?.setBackgroundColor(Color.parseColor("#444455"))
            statusLabel?.text = "Idle"
        }
    }

    /** Set the dot to an active/watching state (purple) */
    fun setActive() {
        handler.post {
            statusDot?.setBackgroundColor(Color.parseColor("#7C4DFF"))
            statusLabel?.text = "Listening"
        }
    }

    private fun canDrawOverlay(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    private fun buildOverlay() {
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Color.parseColor("#CC1A1A2E"))  // semi-transparent dark
            setPadding(24, 14, 24, 14)
        }

        // Status dot
        val dot = View(context).apply {
            setBackgroundColor(Color.parseColor("#7C4DFF"))
            val dp8 = (8 * context.resources.displayMetrics.density).toInt()
            layoutParams = LinearLayout.LayoutParams(dp8, dp8).apply {
                gravity = Gravity.CENTER_VERTICAL
                marginEnd = (10 * context.resources.displayMetrics.density).toInt()
            }
        }
        // Make dot circular via post
        dot.post {
            dot.background = context.getDrawable(android.R.drawable.btn_radio)?.apply {
                setTint(Color.parseColor("#7C4DFF"))
            }
        }

        val label = TextView(context).apply {
            text = "Listening"
            textSize = 11f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
        }

        container.addView(dot)
        container.addView(label)
        statusDot = dot
        statusLabel = label

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = 24
            y = 160
        }

        // Drag support
        container.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (initialTouchX - event.rawX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager.updateViewLayout(v, params)
                    true
                }
                else -> false
            }
        }

        windowManager.addView(container, params)
        overlayView = container
    }
}
