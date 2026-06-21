package com.example.spartial_touch

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.LinearLayout
import android.widget.TextView

/**
 * OverlayManager draws a Dynamic Island overlay centered at the top of the screen
 * around the camera punch-hole using SYSTEM_ALERT_WINDOW.
 * It animates smoothly between compact, listening, and gesture detected states.
 */
class OverlayManager(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())
    
    private var overlayView: View? = null
    private var statusDot: View? = null
    private var statusLabel: TextView? = null
    private var innerContainer: LinearLayout? = null
    private var params: WindowManager.LayoutParams? = null

    private var currentAnimator: ValueAnimator? = null
    private var pulseAnimator: ObjectAnimator? = null

    private val resetRunnable = Runnable {
        setActive()
    }

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
        handler.removeCallbacks(resetRunnable)
        stopPulse()
        currentAnimator?.cancel()
        
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
                innerContainer = null
                params = null
            }
        }
    }

    /**
     * Expand the dynamic island and display the recognized gesture name.
     * @param gestureName The name of the detected gesture.
     */
    fun flashGesture(gestureName: String) {
        handler.post {
            handler.removeCallbacks(resetRunnable)
            stopPulse()
            
            setDotColor("#00E676") // Vibrant green
            statusLabel?.text = gestureName

            animatePillWidth(170, onEnd = {
                handler.postDelayed(resetRunnable, 1000)
            })
        }
    }

    /** Set the island to a sleeping/idle state (compact black pill) */
    fun setSleeping() {
        handler.post {
            handler.removeCallbacks(resetRunnable)
            stopPulse()
            setDotColor("#444455")
            statusLabel?.text = "Idle"
            
            animatePillWidth(36)
        }
    }

    /** Set the island to an active/listening state (expanded pill with pulsing status dot) */
    fun setActive() {
        handler.post {
            handler.removeCallbacks(resetRunnable)
            setDotColor("#7C4DFF") // Elegant purple
            statusLabel?.text = "Listening"
            
            animatePillWidth(120, onEnd = {
                startPulse()
            })
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
        val density = context.resources.displayMetrics.density
        
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            
            val bgDrawable = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 16 * density // Fully rounded capsule
                setColor(Color.BLACK) // Solid black to blend with camera pinhole
                setStroke((1 * density).toInt(), Color.parseColor("#22FFFFFF")) // Premium thin white outline
            }
            background = bgDrawable
        }

        // Content container (faded out when collapsed)
        val inner = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.INVISIBLE
            alpha = 0f
        }

        // Circular status dot
        val dot = View(context).apply {
            val dp8 = (8 * density).toInt()
            layoutParams = LinearLayout.LayoutParams(dp8, dp8).apply {
                gravity = Gravity.CENTER_VERTICAL
                marginEnd = (8 * density).toInt()
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#7C4DFF"))
            }
        }

        val label = TextView(context).apply {
            text = "Listening"
            textSize = 11f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
        }

        inner.addView(dot)
        inner.addView(label)
        container.addView(inner)

        statusDot = dot
        statusLabel = label
        innerContainer = inner

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE

        val initialWidth = (36 * density).toInt()
        val fixedHeight = (32 * density).toInt()

        val lp = WindowManager.LayoutParams(
            initialWidth,
            fixedHeight,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = 0
            y = (8 * density).toInt() // Position overlay precisely around punch-hole camera
        }

        params = lp
        windowManager.addView(container, lp)
        overlayView = container
    }

    private fun animatePillWidth(targetWidthDp: Int, onStart: () -> Unit = {}, onEnd: () -> Unit = {}) {
        val lp = params ?: return
        val view = overlayView ?: return
        
        currentAnimator?.cancel()

        val density = context.resources.displayMetrics.density
        val startWidth = lp.width
        val endWidth = (targetWidthDp * density).toInt()

        if (view.isAttachedToWindow == false) {
            lp.width = endWidth
            onStart()
            if (targetWidthDp > 40) {
                innerContainer?.visibility = View.VISIBLE
                innerContainer?.alpha = 1f
            } else {
                innerContainer?.visibility = View.INVISIBLE
                innerContainer?.alpha = 0f
            }
            onEnd()
            return
        }

        // Fade out content early if we are collapsing to prevent text wrap/squish
        if (targetWidthDp <= 40) {
            innerContainer?.animate()?.alpha(0f)?.setDuration(80)?.start()
        }

        currentAnimator = ValueAnimator.ofInt(startWidth, endWidth).apply {
            duration = 280
            interpolator = OvershootInterpolator(0.8f) // Bouncy spring effect
            addUpdateListener { animation ->
                lp.width = animation.animatedValue as Int
                if (view.isAttachedToWindow) {
                    windowManager.updateViewLayout(view, lp)
                }
            }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationStart(animation: Animator) {
                    onStart()
                }
                override fun onAnimationEnd(animation: Animator) {
                    if (targetWidthDp > 40) {
                        innerContainer?.visibility = View.VISIBLE
                        innerContainer?.animate()?.alpha(1f)?.setDuration(120)?.start()
                    } else {
                        innerContainer?.visibility = View.INVISIBLE
                    }
                    onEnd()
                }
            })
        }
        currentAnimator?.start()
    }

    private fun setDotColor(hexColor: String) {
        statusDot?.background?.let {
            if (it is GradientDrawable) {
                it.setColor(Color.parseColor(hexColor))
            }
        }
    }

    private fun startPulse() {
        statusDot?.let { dot ->
            pulseAnimator?.cancel()
            pulseAnimator = ObjectAnimator.ofFloat(dot, "alpha", 0.3f, 1.0f).apply {
                duration = 800
                repeatMode = ValueAnimator.REVERSE
                repeatCount = ValueAnimator.INFINITE
                start()
            }
        }
    }

    private fun stopPulse() {
        pulseAnimator?.cancel()
        statusDot?.alpha = 1.0f
    }
}
