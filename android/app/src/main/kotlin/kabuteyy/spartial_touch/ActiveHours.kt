package kabuteyy.spartial_touch

import java.util.Calendar

/**
 * The daily active-hours window, checked natively by GestureService so it keeps working
 * after the Flutter UI is closed (the old Dart Timer died with the Flutter engine).
 * Times are minutes since midnight.
 */
object ActiveHours {

    fun isInWindow(now: Calendar, startMinutes: Int, endMinutes: Int): Boolean =
        isInWindow(now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE), startMinutes, endMinutes)

    /** Handles overnight windows (e.g. 22:00–06:00). An empty window (start == end) is never active. */
    fun isInWindow(nowMinutes: Int, startMinutes: Int, endMinutes: Int): Boolean =
        if (startMinutes <= endMinutes) {
            nowMinutes in startMinutes until endMinutes
        } else {
            nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
}
