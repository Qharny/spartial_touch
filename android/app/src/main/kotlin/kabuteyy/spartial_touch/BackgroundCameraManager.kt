package kabuteyy.spartial_touch

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.Image
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class BackgroundCameraManager(
    private val context: Context,
    private val onFrame: (Bitmap, ByteArray, Long) -> Unit
) : LifecycleOwner {

    private val lifecycleRegistry = LifecycleRegistry(this)
    // One executor for the manager's whole life: stop()/start() pairs used to shut it down and
    // recreate it, and a start() racing a pending stop() could bind an analyzer to an executor
    // that was about to be (or already) shut down, silently stalling every frame.
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var imageAnalyzer: ImageAnalysis? = null

    // The most recently requested state. start()/stop() only record intent; the actual
    // bind/unbind runs later on the main executor, and each callback re-checks this so the
    // LAST call always wins — rapid SmartWake wake/sleep flapping can no longer interleave a
    // stale bind after a newer unbind (or vice versa).
    private var wantRunning = false
    private var released = false

    init {
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
    }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    /** Must be called on the main thread. */
    fun start() {
        if (released) return
        wantRunning = true
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            if (!wantRunning || released || imageAnalyzer != null) return@addListener
            val cameraProvider: ProcessCameraProvider = try {
                cameraProviderFuture.get()
            } catch (e: Exception) {
                Log.e("BackgroundCameraManager", "Camera provider unavailable", e)
                return@addListener
            }

            val analyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
            analyzer.setAnalyzer(cameraExecutor) { imageProxy ->
                // An uncaught exception here (OOM during JPEG compression, a buffer
                // closed concurrently, etc.) would crash the whole app — Android
                // kills the process for an uncaught exception on ANY thread, not just
                // main. imageProxy.close() must also always run, or CameraX's
                // STRATEGY_KEEP_ONLY_LATEST backpressure stalls waiting on a buffer
                // that never gets released.
                try {
                    val (bitmap, bytes) = imageProxy.image?.toBitmapAndBytes() ?: Pair(null, null)
                    val timestampMs = imageProxy.imageInfo.timestamp / 1_000_000
                    if (bitmap != null && bytes != null) {
                        onFrame(bitmap, bytes, timestampMs)
                    }
                } catch (e: Exception) {
                    Log.e("BackgroundCameraManager", "Frame processing failed", e)
                } finally {
                    imageProxy.close()
                }
            }

            try {
                cameraProvider.unbindAll()
                lifecycleRegistry.currentState = Lifecycle.State.STARTED
                cameraProvider.bindToLifecycle(this, CameraSelector.DEFAULT_FRONT_CAMERA, analyzer)
                lifecycleRegistry.currentState = Lifecycle.State.RESUMED
                imageAnalyzer = analyzer
            } catch (exc: Exception) {
                Log.e("BackgroundCameraManager", "Use case binding failed", exc)
                analyzer.clearAnalyzer()
                lifecycleRegistry.currentState = Lifecycle.State.CREATED
            }
        }, ContextCompat.getMainExecutor(context))
    }

    /**
     * Must be called on the main thread. Never blocks: stop() is called from SmartWakeManager's
     * sensor callback on the main thread, where a synchronous provider .get() risked an ANR.
     */
    fun stop() {
        wantRunning = false
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            // A start() issued after this stop() supersedes it.
            if (wantRunning && !released) return@addListener
            try {
                cameraProviderFuture.get().unbindAll()
            } catch (e: Exception) {
                Log.e("BackgroundCameraManager", "unbindAll failed during stop()", e)
            }
            imageAnalyzer?.clearAnalyzer()
            imageAnalyzer = null
            // CREATED, not DESTROYED: DESTROYED is terminal for a LifecycleRegistry, so the next
            // start() could never move it back to STARTED.
            lifecycleRegistry.currentState = Lifecycle.State.CREATED
            if (released) {
                lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
                cameraExecutor.shutdown()
            }
        }, ContextCompat.getMainExecutor(context))
    }

    /** Stops the camera for good and frees the analysis thread. Call from Service.onDestroy(). */
    fun release() {
        released = true
        stop()
    }

    private fun Image.toBitmapAndBytes(): Pair<Bitmap?, ByteArray?> {
        if (format != ImageFormat.YUV_420_888) {
            return Pair(null, null)
        }
        val yBuffer = planes[0].buffer // Y
        val vuBuffer = planes[2].buffer // VU

        val ySize = yBuffer.remaining()
        val vuSize = vuBuffer.remaining()

        val nv21 = ByteArray(ySize + vuSize)

        yBuffer.get(nv21, 0, ySize)
        vuBuffer.get(nv21, ySize, vuSize)

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, this.width, this.height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, yuvImage.width, yuvImage.height), 80, out)
        val imageBytes = out.toByteArray()
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        return Pair(bitmap, imageBytes)
    }
}
