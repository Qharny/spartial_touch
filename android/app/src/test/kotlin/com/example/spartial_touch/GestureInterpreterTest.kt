package com.example.spartial_touch

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Unit tests for the fields and public API added to [GestureInterpreter] in this PR:
 *  - [GestureInterpreter.applyCooldown]
 *  - [GestureInterpreter.applyCalibration]
 *
 * Because GestureInterpreter is a Kotlin object (singleton) with mutable state,
 * each test resets the fields to their documented defaults after it runs to avoid
 * cross-test interference.
 *
 * The private fields (cooldownMs, minConfidence, motionThreshold) are read back
 * via reflection so we can assert the mutations without introducing extra public
 * getters in the production code.
 */
class GestureInterpreterTest {

    // ── Reflection helpers ────────────────────────────────────────────────────

    private fun getLongField(name: String): Long {
        val field = GestureInterpreter.javaClass.getDeclaredField(name)
        field.isAccessible = true
        return field.getLong(GestureInterpreter)
    }

    private fun getFloatField(name: String): Float {
        val field = GestureInterpreter.javaClass.getDeclaredField(name)
        field.isAccessible = true
        return field.getFloat(GestureInterpreter)
    }

    // ── Restore defaults after every test ─────────────────────────────────────

    @After
    fun restoreDefaults() {
        GestureInterpreter.applyCooldown(800L)
        GestureInterpreter.applyCalibration(0.75f, 0.12f)
    }

    // ── applyCooldown ──────────────────────────────────────────────────────────

    @Test
    fun `applyCooldown sets cooldownMs field`() {
        GestureInterpreter.applyCooldown(500L)
        assertEquals(500L, getLongField("cooldownMs"))
    }

    @Test
    fun `applyCooldown with zero makes cooldown immediate`() {
        GestureInterpreter.applyCooldown(0L)
        assertEquals(0L, getLongField("cooldownMs"))
    }

    @Test
    fun `applyCooldown with max long does not throw`() {
        GestureInterpreter.applyCooldown(Long.MAX_VALUE)
        assertEquals(Long.MAX_VALUE, getLongField("cooldownMs"))
    }

    @Test
    fun `applyCooldown updates the field when called multiple times`() {
        GestureInterpreter.applyCooldown(300L)
        GestureInterpreter.applyCooldown(2000L)
        assertEquals(2000L, getLongField("cooldownMs"))
    }

    @Test
    fun `applyCooldown with battery-saver value 2000ms`() {
        GestureInterpreter.applyCooldown(2000L)
        assertEquals(2000L, getLongField("cooldownMs"))
    }

    @Test
    fun `applyCooldown with balanced value 800ms`() {
        GestureInterpreter.applyCooldown(800L)
        assertEquals(800L, getLongField("cooldownMs"))
    }

    @Test
    fun `applyCooldown with performance value 300ms`() {
        GestureInterpreter.applyCooldown(300L)
        assertEquals(300L, getLongField("cooldownMs"))
    }

    // ── applyCalibration ───────────────────────────────────────────────────────

    @Test
    fun `applyCalibration sets minConfidence field`() {
        GestureInterpreter.applyCalibration(0.85f, 0.12f)
        assertEquals(0.85f, getFloatField("minConfidence"), 0.0001f)
    }

    @Test
    fun `applyCalibration sets motionThreshold field`() {
        GestureInterpreter.applyCalibration(0.75f, 0.20f)
        assertEquals(0.20f, getFloatField("motionThreshold"), 0.0001f)
    }

    @Test
    fun `applyCalibration sets both fields independently`() {
        GestureInterpreter.applyCalibration(0.60f, 0.08f)
        assertEquals(0.60f, getFloatField("minConfidence"), 0.0001f)
        assertEquals(0.08f, getFloatField("motionThreshold"), 0.0001f)
    }

    @Test
    fun `applyCalibration with minimum allowed confidence 0_50`() {
        GestureInterpreter.applyCalibration(0.50f, 0.12f)
        assertEquals(0.50f, getFloatField("minConfidence"), 0.0001f)
    }

    @Test
    fun `applyCalibration with maximum allowed confidence 0_95`() {
        GestureInterpreter.applyCalibration(0.95f, 0.12f)
        assertEquals(0.95f, getFloatField("minConfidence"), 0.0001f)
    }

    @Test
    fun `applyCalibration with minimum allowed motion threshold 0_06`() {
        GestureInterpreter.applyCalibration(0.75f, 0.06f)
        assertEquals(0.06f, getFloatField("motionThreshold"), 0.0001f)
    }

    @Test
    fun `applyCalibration with maximum allowed motion threshold 0_25`() {
        GestureInterpreter.applyCalibration(0.75f, 0.25f)
        assertEquals(0.25f, getFloatField("motionThreshold"), 0.0001f)
    }

    @Test
    fun `applyCalibration can be called multiple times and last value wins`() {
        GestureInterpreter.applyCalibration(0.60f, 0.08f)
        GestureInterpreter.applyCalibration(0.90f, 0.22f)
        assertEquals(0.90f, getFloatField("minConfidence"), 0.0001f)
        assertEquals(0.22f, getFloatField("motionThreshold"), 0.0001f)
    }

    // ── Default field values ───────────────────────────────────────────────────

    @Test
    fun `cooldownMs default is 800ms`() {
        // Restore to known state first (in case a previous test changed it)
        GestureInterpreter.applyCooldown(800L)
        assertEquals(800L, getLongField("cooldownMs"))
    }

    @Test
    fun `minConfidence default is 0_75`() {
        GestureInterpreter.applyCalibration(0.75f, 0.12f)
        assertEquals(0.75f, getFloatField("minConfidence"), 0.0001f)
    }

    @Test
    fun `motionThreshold default is 0_12`() {
        GestureInterpreter.applyCalibration(0.75f, 0.12f)
        assertEquals(0.12f, getFloatField("motionThreshold"), 0.0001f)
    }

    // ── Regression: applyCooldown does not affect calibration fields ───────────

    @Test
    fun `applyCooldown does not alter minConfidence`() {
        GestureInterpreter.applyCalibration(0.88f, 0.14f)
        GestureInterpreter.applyCooldown(1500L)
        assertEquals(0.88f, getFloatField("minConfidence"), 0.0001f)
    }

    @Test
    fun `applyCooldown does not alter motionThreshold`() {
        GestureInterpreter.applyCalibration(0.88f, 0.14f)
        GestureInterpreter.applyCooldown(1500L)
        assertEquals(0.14f, getFloatField("motionThreshold"), 0.0001f)
    }

    // ── Regression: applyCalibration does not affect cooldown ─────────────────

    @Test
    fun `applyCalibration does not alter cooldownMs`() {
        GestureInterpreter.applyCooldown(400L)
        GestureInterpreter.applyCalibration(0.80f, 0.16f)
        assertEquals(400L, getLongField("cooldownMs"))
    }
}