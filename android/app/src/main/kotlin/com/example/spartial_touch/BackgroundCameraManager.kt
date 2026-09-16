package com.example.spartial_touch

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
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var imageAnalyzer: ImageAnalysis? = null

    init {
        lifecycleRegistry.currentState = Lifecycle.State.CREATED
    }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    fun start() {
        if (cameraExecutor.isShutdown) {
            cameraExecutor = Executors.newSingleThreadExecutor()
        }
        lifecycleRegistry.currentState = Lifecycle.State.STARTED
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

            imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor) { imageProxy ->
                        // An uncaught exception here (OOM during JPEG compression, a buffer
                        // closed concurrently, etc.) would crash the whole app — Android
                        // kills the process for an uncaught exception on ANY thread, not just
                        // main. imageProxy.close() must also always run, or CameraX's
                        // STRATEGY_KEEP_ONLY_LATEST backpressure stalls waiting on a buffer
                        // that never gets released.
                        try {
                            val (bitmap, bytes) = imageProxy.image?.toBitmapAndBytes() ?: Pair(null, null)
                            val timestampNs = imageProxy.imageInfo.timestamp
                            val timestampMs = timestampNs / 1_000_000
                            if (bitmap != null && bytes != null) {
                                onFrame(bitmap, bytes, timestampMs)
                            }
                        } catch (e: Exception) {
                            Log.e("BackgroundCameraManager", "Frame processing failed", e)
                        } finally {
                            imageProxy.close()
                        }
                    }
                }

            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    this, cameraSelector, imageAnalyzer
                )
                lifecycleRegistry.currentState = Lifecycle.State.RESUMED
            } catch (exc: Exception) {
                Log.e("BackgroundCameraManager", "Use case binding failed", exc)
            }

        }, ContextCompat.getMainExecutor(context))
    }

    fun stop() {
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        // stop() is called from SmartWakeManager's sensor callback, which runs on the main
        // thread (registered with no Handler) — a blocking .get() here risked an ANR. Mirror
        // start()'s async addListener pattern instead; the executor is only shut down once
        // unbindAll() actually completes, so no frame can be submitted to it in between.
        cameraProviderFuture.addListener({
            try {
                cameraProviderFuture.get().unbindAll()
            } catch (e: Exception) {
                Log.e("BackgroundCameraManager", "unbindAll failed during stop()", e)
            } finally {
                cameraExecutor.shutdown()
            }
        }, ContextCompat.getMainExecutor(context))
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
