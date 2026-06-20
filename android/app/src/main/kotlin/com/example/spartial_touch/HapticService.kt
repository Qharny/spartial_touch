package com.example.spartial_touch

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * HapticService provides gesture-recognition haptic feedback.
 * It produces a short, crisp pulse on every confirmed gesture event.
 */
object HapticService {

    private const val TAG = "HapticService"

    /**
     * Fire a short haptic pulse to signal a recognised gesture.
     * @param context Any application/service context.
     * @param style   "light" (50 ms) | "medium" (80 ms) | "heavy" (120 ms)
     */
    fun pulse(context: Context, style: String = "medium") {
        try {
            val durationMs = when (style) {
                "light"  -> 40L
                "heavy"  -> 110L
                else     -> 70L  // medium default
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val vibrator = vm.defaultVibrator
                vibrator.vibrate(
                    VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                vibrator.vibrate(
                    VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                @Suppress("DEPRECATION")
                vibrator.vibrate(durationMs)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Haptic pulse failed: ${e.message}")
        }
    }

    /**
     * Double pulse — used for error / rejected gesture feedback.
     */
    fun doublePulse(context: Context) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val pattern = longArrayOf(0, 50, 80, 50)
                val amplitudes = intArrayOf(0, 180, 0, 120)
                val effect = VibrationEffect.createWaveform(pattern, amplitudes, -1)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                    vm.defaultVibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    vibrator.vibrate(effect)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Double pulse failed: ${e.message}")
        }
    }
}
