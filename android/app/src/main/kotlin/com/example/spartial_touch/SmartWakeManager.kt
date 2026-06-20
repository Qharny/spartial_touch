package com.example.spartial_touch

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log

/**
 * SmartWakeManager monitors the proximity sensor and accelerometer to determine
 * when a hand is likely approaching the device. The camera is only active when
 * a potential gesture scenario is detected, preserving battery life.
 *
 * Logic:
 *  - Proximity NEAR  → something is close to the front (possible hand)
 *  - Accelerometer stable (low magnitude change) → phone is resting on a surface
 *  Both conditions together → wake camera
 */
class SmartWakeManager(
    private val context: Context,
    private val onWake: () -> Unit,
    private val onSleep: () -> Unit
) : SensorEventListener {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val proximitySensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    // State
    private var isProximityNear = false
    private var isPhoneStable = true
    private var lastAccelMagnitude = 9.8f  // ~gravity at rest
    private var isWake = false

    fun start() {
        proximitySensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        } ?: Log.w("SmartWake", "No proximity sensor available")

        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        } ?: Log.w("SmartWake", "No accelerometer available")

        // If device has no proximity sensor, keep camera always on
        if (proximitySensor == null) {
            triggerWake()
        }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
        if (isWake) {
            isWake = false
            onSleep()
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_PROXIMITY -> {
                val maxRange = event.sensor.maximumRange
                isProximityNear = event.values[0] < maxRange * 0.5f
                evaluateWakeCondition()
            }
            Sensor.TYPE_ACCELEROMETER -> {
                val x = event.values[0]
                val y = event.values[1]
                val z = event.values[2]
                val magnitude = Math.sqrt((x * x + y * y + z * z).toDouble()).toFloat()
                val delta = Math.abs(magnitude - lastAccelMagnitude)
                lastAccelMagnitude = magnitude
                // Consider stable if acceleration delta is low (phone is resting)
                isPhoneStable = delta < 1.5f
                evaluateWakeCondition()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun evaluateWakeCondition() {
        val shouldWake = isProximityNear && isPhoneStable
        if (shouldWake && !isWake) {
            triggerWake()
        } else if (!shouldWake && isWake) {
            isWake = false
            Log.d("SmartWake", "Sleeping — no hand detected")
            onSleep()
        }
    }

    private fun triggerWake() {
        isWake = true
        Log.d("SmartWake", "Waking — hand approaching detected")
        onWake()
    }
}
