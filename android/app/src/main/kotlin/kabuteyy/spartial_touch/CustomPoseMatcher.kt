package kabuteyy.spartial_touch

import org.json.JSONArray

/**
 * Recognises user-recorded custom hand poses.
 *
 * A pose is stored as one or more samples of the 21 MediaPipe landmarks, flattened to
 * `[x0, y0, x1, y1, …]`. Every frame and every sample goes through [normalize] first — wrist
 * moved to the origin, scaled so wrist→middle-finger-MCP is 1 — so a pose matches regardless
 * of where the hand sits in frame or how far it is from the camera. Orientation is kept on
 * purpose: a thumbs-up and a thumbs-down must stay different poses.
 *
 * The same normalisation and distance are implemented in Dart (custom_pose.dart) for the
 * recording wizard's live test; keep the two in sync.
 */
object CustomPoseMatcher {

    class Pose(val key: String, val samples: List<FloatArray>)

    const val POINTS = 21
    private const val MIDDLE_MCP = 9

    /** Mean per-landmark distance, in normalised hand units, at the default sensitivity. */
    const val BASE_MATCH_THRESHOLD = 0.35f

    /** Consecutive matching frames needed before a pose fires (~0.4s at 15fps). */
    const val HOLD_FRAMES = 6

    @Volatile
    private var poses: List<Pose> = emptyList()

    // Only touched from MediaPipe's result-listener thread.
    private var candidateKey: String? = null
    private var candidateFrames = 0

    fun setPoses(newPoses: List<Pose>) {
        poses = newPoses
        reset()
    }

    fun hasPoses(): Boolean = poses.isNotEmpty()

    fun reset() {
        candidateKey = null
        candidateFrames = 0
    }

    /** Returns a translation/scale-invariant copy of [raw], or null if it can't be normalised. */
    fun normalize(raw: FloatArray): FloatArray? {
        if (raw.size != POINTS * 2) return null
        val wx = raw[0]
        val wy = raw[1]
        val mx = raw[MIDDLE_MCP * 2] - wx
        val my = raw[MIDDLE_MCP * 2 + 1] - wy
        val scale = Math.sqrt((mx * mx + my * my).toDouble()).toFloat()
        if (scale < 1e-4f) return null
        return FloatArray(raw.size) { i -> (raw[i] - if (i % 2 == 0) wx else wy) / scale }
    }

    /** Mean Euclidean distance between corresponding landmarks of two normalised poses. */
    fun distance(a: FloatArray, b: FloatArray): Float {
        var sum = 0.0
        for (p in 0 until POINTS) {
            val dx = a[p * 2] - b[p * 2]
            val dy = a[p * 2 + 1] - b[p * 2 + 1]
            sum += Math.sqrt((dx * dx + dy * dy).toDouble())
        }
        return (sum / POINTS).toFloat()
    }

    /** Closest pose to [frame] (already normalised) as key → distance, or null with no poses. */
    fun bestMatch(frame: FloatArray): Pair<String, Float>? {
        var bestKey: String? = null
        var bestDist = Float.MAX_VALUE
        for (pose in poses) {
            for (sample in pose.samples) {
                val d = distance(frame, sample)
                if (d < bestDist) {
                    bestDist = d
                    bestKey = pose.key
                }
            }
        }
        return bestKey?.let { it to bestDist }
    }

    /**
     * Feeds one normalised frame. Returns key → score (0.5–1.0, higher is closer) once the same
     * pose has been held for [HOLD_FRAMES] consecutive frames, otherwise null.
     * [thresholdFor] gives the match radius for a pose key (scaled by its sensitivity).
     */
    fun update(frame: FloatArray, thresholdFor: (String) -> Float): Pair<String, Float>? {
        val match = bestMatch(frame)
        if (match == null) {
            reset()
            return null
        }
        val (key, dist) = match
        val threshold = thresholdFor(key)
        if (dist > threshold) {
            reset()
            return null
        }
        if (key == candidateKey) candidateFrames++ else {
            candidateKey = key
            candidateFrames = 1
        }
        if (candidateFrames < HOLD_FRAMES) return null
        reset()
        return key to (1f - 0.5f * (dist / threshold))
    }

    /**
     * Parses the JSON pushed from Flutter:
     * `[{"key":"CUSTOM_1","samples":[[x0,y0,…],[…]]}, …]`. Samples are normalised here so
     * callers can pass raw landmarks. Malformed entries are skipped.
     */
    fun parse(json: String): List<Pose> {
        val result = mutableListOf<Pose>()
        val arr = try { JSONArray(json) } catch (e: Exception) { return result }
        for (i in 0 until arr.length()) {
            val obj = arr.optJSONObject(i) ?: continue
            val key = obj.optString("key").takeIf { it.isNotEmpty() } ?: continue
            val samplesJson = obj.optJSONArray("samples") ?: continue
            val samples = mutableListOf<FloatArray>()
            for (s in 0 until samplesJson.length()) {
                val pts = samplesJson.optJSONArray(s) ?: continue
                if (pts.length() != POINTS * 2) continue
                val raw = FloatArray(POINTS * 2) { pts.optDouble(it, 0.0).toFloat() }
                normalize(raw)?.let { samples.add(it) }
            }
            if (samples.isNotEmpty()) result.add(Pose(key, samples))
        }
        return result
    }
}
