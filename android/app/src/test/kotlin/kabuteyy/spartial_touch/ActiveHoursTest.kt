package kabuteyy.spartial_touch

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ActiveHoursTest {
    private fun t(h: Int, m: Int = 0) = h * 60 + m

    @Test
    fun `daytime window includes start and excludes end`() {
        assertTrue(ActiveHours.isInWindow(t(8), t(8), t(22)))
        assertTrue(ActiveHours.isInWindow(t(21, 59), t(8), t(22)))
        assertFalse(ActiveHours.isInWindow(t(22), t(8), t(22)))
        assertFalse(ActiveHours.isInWindow(t(7, 59), t(8), t(22)))
    }

    @Test
    fun `overnight window wraps past midnight`() {
        assertTrue(ActiveHours.isInWindow(t(23), t(22), t(6)))
        assertTrue(ActiveHours.isInWindow(t(5, 59), t(22), t(6)))
        assertFalse(ActiveHours.isInWindow(t(12), t(22), t(6)))
    }

    @Test
    fun `empty window is never active`() {
        assertFalse(ActiveHours.isInWindow(t(9), t(9), t(9)))
    }
}
