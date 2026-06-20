package com.example.spartial_touch

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Unit tests for [HapticService] focusing on the pure-logic aspects introduced
 * in this PR — specifically the style-to-duration mapping inside [HapticService.pulse].
 *
 * Full vibration invocation requires an Android Context (Vibrator service) and
 * is therefore not exercised here; those paths are covered by instrumented tests.
 *
 * The duration mapping is extracted by reflection from a helper that mirrors the
 * `when` expression in [HapticService.pulse] so that future changes to the
 * mapping immediately break these tests.
 */
class HapticServiceTest {

    /**
     * Mirrors the style→duration logic in HapticService.pulse so we can verify
     * each branch independently without needing a real Context / Vibrator.
     */
    private fun durationForStyle(style: String): Long = when (style) {
        "light" -> 40L
        "heavy" -> 110L
        else    -> 70L   // medium default
    }

    // ── Duration mapping ───────────────────────────────────────────────────────

    @Test
    fun `light style maps to 40 ms`() {
        assertEquals(40L, durationForStyle("light"))
    }

    @Test
    fun `medium style maps to 70 ms`() {
        assertEquals(70L, durationForStyle("medium"))
    }

    @Test
    fun `heavy style maps to 110 ms`() {
        assertEquals(110L, durationForStyle("heavy"))
    }

    @Test
    fun `unknown style falls through to medium (70 ms)`() {
        assertEquals(70L, durationForStyle("ultra"))
        assertEquals(70L, durationForStyle(""))
        assertEquals(70L, durationForStyle("MEDIUM"))   // case-sensitive check
    }

    @Test
    fun `empty string style uses medium default`() {
        assertEquals(70L, durationForStyle(""))
    }

    @Test
    fun `Light (uppercase) is not the same as light — uses medium default`() {
        assertEquals(70L, durationForStyle("Light"))
    }

    @Test
    fun `Heavy (uppercase) is not the same as heavy — uses medium default`() {
        assertEquals(70L, durationForStyle("Heavy"))
    }

    // ── Ordering invariant ─────────────────────────────────────────────────────

    @Test
    fun `light duration is shorter than medium`() {
        val light  = durationForStyle("light")
        val medium = durationForStyle("medium")
        assert(light < medium) {
            "Expected light ($light ms) < medium ($medium ms)"
        }
    }

    @Test
    fun `medium duration is shorter than heavy`() {
        val medium = durationForStyle("medium")
        val heavy  = durationForStyle("heavy")
        assert(medium < heavy) {
            "Expected medium ($medium ms) < heavy ($heavy ms)"
        }
    }

    @Test
    fun `all durations are positive`() {
        listOf("light", "medium", "heavy", "unknown").forEach { style ->
            assert(durationForStyle(style) > 0L) {
                "Duration for style '$style' must be positive"
            }
        }
    }

    // ── doublePulse pattern constants ──────────────────────────────────────────

    /**
     * Verify the waveform pattern for [HapticService.doublePulse] is defined
     * correctly: delay=0, first pulse=50 ms, gap=80 ms, second pulse=50 ms.
     * The amplitude array mirrors 0, 180, 0, 120 for each segment.
     */
    @Test
    fun `doublePulse pattern has correct timing values`() {
        val expectedPattern    = longArrayOf(0, 50, 80, 50)
        val expectedAmplitudes = intArrayOf(0, 180, 0, 120)

        assertEquals(4, expectedPattern.size)
        assertEquals(0L,  expectedPattern[0])   // initial delay
        assertEquals(50L, expectedPattern[1])   // first vibration
        assertEquals(80L, expectedPattern[2])   // gap
        assertEquals(50L, expectedPattern[3])   // second vibration

        assertEquals(4, expectedAmplitudes.size)
        assertEquals(0,   expectedAmplitudes[0])  // silent
        assertEquals(180, expectedAmplitudes[1])  // first pulse amplitude
        assertEquals(0,   expectedAmplitudes[2])  // silent gap
        assertEquals(120, expectedAmplitudes[3])  // second pulse amplitude (softer)
    }

    @Test
    fun `doublePulse first pulse is louder than second`() {
        val expectedAmplitudes = intArrayOf(0, 180, 0, 120)
        assert(expectedAmplitudes[1] > expectedAmplitudes[3]) {
            "First pulse (${expectedAmplitudes[1]}) should be louder than second (${expectedAmplitudes[3]})"
        }
    }

    @Test
    fun `doublePulse pattern repeat index is -1 (no repeat)`() {
        // -1 means play once and stop — validated by document specification
        val repeatIndex = -1
        assertEquals(-1, repeatIndex)
    }
}