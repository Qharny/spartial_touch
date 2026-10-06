package kabuteyy.spartial_touch

import android.content.Context
import android.media.AudioManager
import android.util.Log

/**
 * ActionDispatcher maps incoming gesture keys to concrete Android actions.
 * It is driven by a profile mapping (gestureKey → actionId) that is loaded
 * from the Flutter side via the MethodChannel.
 *
 * Supported actionIds:
 *   scroll_up, scroll_down, swipe_left, swipe_right, tap,
 *   back, home, recents,
 *   media_play_pause, media_next, media_previous,
 *   volume_up, volume_down,
 *   screenshot
 */
class ActionDispatcher(private val context: Context) {

    companion object {
        /** Actions that are injected through the AccessibilityService rather than AudioManager. */
        private val ACCESSIBILITY_ACTIONS = setOf(
            "scroll_up", "scroll_down", "swipe_left", "swipe_right", "tap",
            "back", "home", "recents", "screenshot"
        )

        fun requiresAccessibility(actionId: String) = actionId in ACCESSIBILITY_ACTIONS
    }

    // Current mapping: gesture key → action id, resolved for the foreground app.
    // setMappings() runs on the main thread (profile switches / saves) while dispatch() is
    // read from HandTracker's MediaPipe result-listener thread. Swapping an immutable
    // snapshot through a volatile reference means a reader never observes a half-filled map
    // (clear()+putAll() on a shared map briefly exposed an empty mapping to the gesture thread).
    @Volatile
    private var mappings: Map<String, String> = emptyMap()

    /** Update the active mapping (called from GestureService when the profile or foreground app changes) */
    fun setMappings(newMappings: Map<String, String>) {
        mappings = HashMap(newMappings)
        Log.d("ActionDispatcher", "Profile loaded: $mappings")
    }

    /**
     * Dispatch the action for the given gesture payload ("GESTURE_KEY:confidence").
     * Returns true if an action was dispatched, false if no mapping was found.
     */
    fun dispatch(gesturePayload: String): Boolean {
        val gestureKey = gesturePayload.substringBefore(':')
        val actionId = mappings[gestureKey] ?: return false

        Log.d("ActionDispatcher", "Dispatching: $gestureKey → $actionId")
        return execute(actionId)
    }

    /**
     * Runs a single action by id, independent of any gesture mapping — used both by [dispatch]
     * and by the app's "test this action" button. Returns false if the action is unknown or
     * needs the AccessibilityService and it isn't connected.
     */
    fun execute(actionId: String): Boolean {
        val accessibility = SpatialTouchAccessibilityService.instance
        if (requiresAccessibility(actionId) && accessibility == null) {
            Log.w("ActionDispatcher", "Accessibility service not connected — cannot run $actionId")
            return false
        }

        return when (actionId) {
            // Touch injection via AccessibilityService
            "scroll_up", "scroll_down",
            "swipe_left", "swipe_right",
            "tap" -> {
                accessibility?.dispatchTouchGesture(actionId)
                true
            }

            // System navigation
            "back"    -> { accessibility?.performSystemAction("back"); true }
            "home"    -> { accessibility?.performSystemAction("home"); true }
            "recents" -> { accessibility?.performSystemAction("recents"); true }

            // Media controls via AudioManager broadcast
            "media_play_pause" -> { sendMediaKey(android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE); true }
            "media_next"       -> { sendMediaKey(android.view.KeyEvent.KEYCODE_MEDIA_NEXT); true }
            "media_previous"   -> { sendMediaKey(android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS); true }

            // Volume
            "volume_up" -> {
                audioManager().adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_RAISE,
                    AudioManager.FLAG_SHOW_UI
                )
                true
            }
            "volume_down" -> {
                audioManager().adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_LOWER,
                    AudioManager.FLAG_SHOW_UI
                )
                true
            }

            // Screenshot via global action
            "screenshot" -> {
                accessibility?.performGlobalAction(
                    android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_TAKE_SCREENSHOT
                )
                true
            }

            else -> {
                Log.w("ActionDispatcher", "Unknown actionId: $actionId")
                false
            }
        }
    }

    private fun audioManager() =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun sendMediaKey(keyCode: Int) {
        val am = audioManager()
        val downEvent = android.view.KeyEvent(
            android.view.KeyEvent.ACTION_DOWN, keyCode
        )
        val upEvent = android.view.KeyEvent(
            android.view.KeyEvent.ACTION_UP, keyCode
        )
        am.dispatchMediaKeyEvent(downEvent)
        am.dispatchMediaKeyEvent(upEvent)
    }
}
