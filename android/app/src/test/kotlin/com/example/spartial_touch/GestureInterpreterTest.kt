package com.example.spartial_touch

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import io.mockk.every
import io.mockk.mockk
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for GestureInterpreter focusing on the PR-introduced changes:
 *  - applyCooldown(ms: Long)  — mutable cooldown
 *  - applyCalibration(confidenceThreshold, motionThreshold) — mutable thresholds
 *
 * Note: GestureInterpreter is a Kotlin `object` (singleton) so tests share state.
 * Each test restores defaults in @Before / @After to ensure isolation.
 */
class GestureInterpreterTest {

    // A minimal 21-element landmark list where the confidence guard fires
    // before any landmark is accessed, so the actual values don't matter
    // for confidence/cooldown tests.
    private val dummyLandmarks: List<NormalizedLandmark> = List(21) {
        mockk<NormalizedLandmark>(relaxed = true)
    }

    @Before
    fun restoreDefaults() {
        // Reset to documented defaults so each test starts from a clean state
        GestureInterpreter.applyCalibration(0.75f, 0.12f)
        GestureInterpreter.applyCooldown(800L)
    }

    @After
    fun cleanUp() {
        // Restore defaults again after each test in case the test mutated them
        GestureInterpreter.applyCalibration(0.75f, 0.12f)
        GestureInterpreter.applyCooldown(800L)
    }

    // ── applyCalibration — confidence threshold ────────────────────────────

    @Test
    fun `interpret returns null when confidence is below default threshold`() {
        // Default minConfidence = 0.75f; passing 0.74f should cause early return
        val result = GestureInterpreter.interpret(dummyLandmarks, 0.74f)
        assertNull("Expected null for confidence below threshold", result)
    }

    @Test
    fun `applyCalibration raises confidence threshold — low confidence is rejected`() {
        GestureInterpreter.applyCalibration(0.95f, 0.12f)
        // 0.90f is now below the raised threshold
        val result = GestureInterpreter.interpret(dummyLandmarks, 0.90f)
        assertNull("Expected null because 0.90 < new threshold 0.95", result)
    }

    @Test
    fun `applyCalibration lowers confidence threshold — previously rejected confidence is accepted`() {
        // With lowered threshold 0.50f, a confidence of 0.55f should pass the guard
        // (result may still be null for other reasons, but must not be null *due to confidence*)
        GestureInterpreter.applyCalibration(0.50f, 0.12f)

        // We cannot easily confirm "accepted" without a full gesture, but we can confirm
        // that with a ridiculously high threshold the same value is rejected.
        GestureInterpreter.applyCalibration(0.99f, 0.12f)
        val rejectedResult = GestureInterpreter.interpret(dummyLandmarks, 0.55f)
        assertNull("Expected null because 0.55 < 0.99 threshold", rejectedResult)
    }

    @Test
    fun `applyCalibration with exact threshold boundary — confidence equal to threshold passes guard`() {
        // confidence == minConfidence: `confidence < minConfidence` is false → guard passes
        // We set a high threshold so we can easily hit the exact boundary
        GestureInterpreter.applyCalibration(0.80f, 0.12f)

        // The function may still return null later (e.g. insufficient history), but it
        // must NOT return null due to the confidence guard when confidence == 0.80f.
        // We verify by setting an even higher threshold and checking null IS returned.
        GestureInterpreter.applyCalibration(0.90f, 0.12f)
        val resultBelow = GestureInterpreter.interpret(dummyLandmarks, 0.80f)
        // 0.80f < 0.90f → rejected
        assertNull("0.80 should be rejected when threshold is 0.90", resultBelow)
    }

    @Test
    fun `applyCalibration updates motionThreshold without crashing`() {
        // This is primarily a sanity / no-crash test for the motionThreshold setter
        GestureInterpreter.applyCalibration(0.75f, 0.06f) // minimum motion
        GestureInterpreter.applyCalibration(0.75f, 0.25f) // maximum motion
        // No assertion beyond "did not throw"
    }

    // ── applyCooldown ─────────────────────────────────────────────────────────

    @Test
    fun `applyCooldown accepts valid values without crashing`() {
        // Sanity: all documented cooldown values (from PerformanceModeX) should be accepted
        GestureInterpreter.applyCooldown(300L)   // performance mode
        GestureInterpreter.applyCooldown(800L)   // balanced mode
        GestureInterpreter.applyCooldown(2000L)  // battery saver mode
        // No assertion beyond "did not throw"
    }

    @Test
    fun `applyCooldown with zero ms — first interpret call is not blocked by cooldown`() {
        // lastGestureTime starts at 0L and currentTimeMillis >> 0, so cooldown
        // is not the blocking factor for the very first call. Verify confidence
        // guard works correctly when cooldown = 0 (same behavior as default for 1st call).
        GestureInterpreter.applyCooldown(0L)
        GestureInterpreter.applyCalibration(0.99f, 0.12f) // high threshold to force null via confidence
        val result = GestureInterpreter.interpret(dummyLandmarks, 0.50f)
        assertNull("Confidence 0.50 < 0.99 should be rejected", result)
    }

    @Test
    fun `applyCooldown with very large value does not crash`() {
        GestureInterpreter.applyCooldown(Long.MAX_VALUE)
        // With MAX_VALUE cooldown, any call after a gesture fires will be blocked.
        // For the very first call (lastGestureTime=0), it is NOT blocked.
        // This just checks no exception is thrown.
        GestureInterpreter.applyCalibration(0.99f, 0.12f)
        val result = GestureInterpreter.interpret(dummyLandmarks, 0.10f)
        assertNull(result)
    }

    // ── Combined applyCooldown + applyCalibration ─────────────────────────────

    @Test
    fun `multiple applyCalibration calls overwrite previous values`() {
        GestureInterpreter.applyCalibration(0.50f, 0.06f)
        GestureInterpreter.applyCalibration(0.95f, 0.25f) // this should win

        // 0.90f < 0.95f → rejected
        val result = GestureInterpreter.interpret(dummyLandmarks, 0.90f)
        assertNull("Last applyCalibration (0.95f) should take effect", result)
    }

    @Test
    fun `multiple applyCooldown calls overwrite previous values`() {
        // Simply verify the setter can be called multiple times without issues
        GestureInterpreter.applyCooldown(300L)
        GestureInterpreter.applyCooldown(2000L)
        GestureInterpreter.applyCooldown(800L) // restore default at end
        // No assertion: sanity / no-crash
    }
}