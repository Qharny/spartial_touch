package kabuteyy.spartial_touch

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CustomPoseMatcherTest {

    /** A synthetic open hand: wrist at (cx, cy), fingers spread upward, scaled by [size]. */
    private fun openHand(cx: Float = 0.5f, cy: Float = 0.8f, size: Float = 0.2f): FloatArray {
        val base = floatArrayOf(
            0f, 0f, -0.3f, -0.2f, -0.5f, -0.45f, -0.65f, -0.65f, -0.8f, -0.85f,
            -0.3f, -0.9f, -0.35f, -1.3f, -0.38f, -1.55f, -0.4f, -1.8f,
            0f, -1f, 0f, -1.45f, 0f, -1.75f, 0f, -2f,
            0.25f, -0.95f, 0.3f, -1.35f, 0.33f, -1.6f, 0.35f, -1.8f,
            0.45f, -0.8f, 0.55f, -1.1f, 0.6f, -1.3f, 0.65f, -1.45f,
        )
        return FloatArray(base.size) { i -> (if (i % 2 == 0) cx else cy) + base[i] * size }
    }

    /** Same hand with all four fingers folded down toward the palm. */
    private fun fist(cx: Float = 0.5f, cy: Float = 0.8f, size: Float = 0.2f): FloatArray {
        val open = openHand(0f, 0f, 1f)
        val folded = open.copyOf()
        for (p in 6..20) {
            if (p % 4 == 0 || p % 4 == 3) folded[p * 2 + 1] = open[p * 2 + 1] * 0.2f
        }
        return FloatArray(folded.size) { i -> (if (i % 2 == 0) cx else cy) + folded[i] * size }
    }

    private fun json(key: String, sample: FloatArray) =
        """[{"key":"$key","samples":[[${sample.joinToString(",")}]]}]"""

    @After
    fun clear() = CustomPoseMatcher.setPoses(emptyList())

    @Test
    fun `normalize puts the wrist at the origin and middle MCP at unit distance`() {
        val n = CustomPoseMatcher.normalize(openHand())!!
        assertEquals(0f, n[0], 1e-5f)
        assertEquals(0f, n[1], 1e-5f)
        val d = Math.sqrt((n[18] * n[18] + n[19] * n[19]).toDouble())
        assertEquals(1.0, d, 1e-4)
    }

    @Test
    fun `normalize rejects wrong-sized or degenerate input`() {
        assertNull(CustomPoseMatcher.normalize(FloatArray(10)))
        assertNull(CustomPoseMatcher.normalize(FloatArray(42)))
    }

    @Test
    fun `the same pose matches regardless of position and distance from the camera`() {
        val a = CustomPoseMatcher.normalize(openHand(0.3f, 0.7f, 0.15f))!!
        val b = CustomPoseMatcher.normalize(openHand(0.6f, 0.9f, 0.3f))!!
        assertTrue(CustomPoseMatcher.distance(a, b) < 1e-4f)
    }

    @Test
    fun `different poses are further apart than the match threshold`() {
        val a = CustomPoseMatcher.normalize(openHand())!!
        val b = CustomPoseMatcher.normalize(fist())!!
        assertTrue(CustomPoseMatcher.distance(a, b) > CustomPoseMatcher.BASE_MATCH_THRESHOLD)
    }

    @Test
    fun `parse reads poses and skips malformed entries`() {
        val good = openHand().joinToString(",")
        val poses = CustomPoseMatcher.parse(
            """[{"key":"CUSTOM_1","samples":[[$good]]},{"key":"","samples":[[$good]]},{"key":"CUSTOM_2","samples":[[1,2,3]]}]"""
        )
        assertEquals(listOf("CUSTOM_1"), poses.map { it.key })
        assertEquals(emptyList<Any>(), CustomPoseMatcher.parse("not json"))
    }

    @Test
    fun `update fires only after the pose is held for HOLD_FRAMES frames`() {
        CustomPoseMatcher.setPoses(CustomPoseMatcher.parse(json("CUSTOM_1", openHand())))
        val frame = CustomPoseMatcher.normalize(openHand(0.4f, 0.75f, 0.25f))!!
        repeat(CustomPoseMatcher.HOLD_FRAMES - 1) {
            assertNull(CustomPoseMatcher.update(frame) { CustomPoseMatcher.BASE_MATCH_THRESHOLD })
        }
        val hit = CustomPoseMatcher.update(frame) { CustomPoseMatcher.BASE_MATCH_THRESHOLD }
        assertNotNull(hit)
        assertEquals("CUSTOM_1", hit!!.first)
        assertTrue(hit.second in 0.5f..1f)
    }

    @Test
    fun `a non-matching frame resets the hold counter`() {
        CustomPoseMatcher.setPoses(CustomPoseMatcher.parse(json("CUSTOM_1", openHand())))
        val match = CustomPoseMatcher.normalize(openHand())!!
        val other = CustomPoseMatcher.normalize(fist())!!
        repeat(CustomPoseMatcher.HOLD_FRAMES - 1) { CustomPoseMatcher.update(match) { 0.35f } }
        assertNull(CustomPoseMatcher.update(other) { 0.35f })
        assertNull(CustomPoseMatcher.update(match) { 0.35f })
    }
}
