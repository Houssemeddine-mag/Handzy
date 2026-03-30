package com.fingertip.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.hardware.camera2.*
import android.media.Image
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Size
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class MediaPipeHelper(private val context: Context) {

    private var handLandmarker: HandLandmarker? = null
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    private var landmarksCallback: ((List<Map<String, Any>>) -> Unit)? = null
    private var isTracking = false

    companion object {
        private const val TAG = "MediaPipeHelper"
        private const val IMAGE_WIDTH = 640
        private const val IMAGE_HEIGHT = 480
    }

    fun initialize(): Boolean {
        return try {
            // Extract model from assets
            val modelFile = extractModelFromAssets()

            // Create HandLandmarker
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(modelFile.absolutePath)
                .build()

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.VIDEO)
                .setNumHands(1)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, options)
            Log.d(TAG, "MediaPipe initialized successfully")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize MediaPipe", e)
            false
        }
    }

    private fun extractModelFromAssets(): File {
        val modelFile = File(context.filesDir, "hand_landmarker.task")
        if (!modelFile.exists()) {
            // Flutter puts its declared assets under "flutter_assets/"
            context.assets.open("flutter_assets/assets/models/hand_landmarker.task").use { input ->
                FileOutputStream(modelFile).use { output ->
                    input.copyTo(output)
                }
            }
        }
        return modelFile
    }

    fun startTracking() {
        if (isTracking) return

        startBackgroundThread()
        openCamera()
        isTracking = true
        Log.d(TAG, "Tracking started")
    }

    fun stopTracking() {
        if (!isTracking) return

        closeCamera()
        stopBackgroundThread()
        isTracking = false
        Log.d(TAG, "Tracking stopped")
    }

    fun setLandmarksCallback(callback: ((List<Map<String, Any>>) -> Unit)?) {
        landmarksCallback = callback
    }

    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("CameraBackground").also { it.start() }
        backgroundHandler = Handler(backgroundThread!!.looper)
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (e: InterruptedException) {
            Log.e(TAG, "Error stopping background thread", e)
        }
    }

    private fun openCamera() {
        try {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val frontCameraId = getFrontCameraId(cameraManager) ?: return

            imageReader = ImageReader.newInstance(
                IMAGE_WIDTH,
                IMAGE_HEIGHT,
                ImageFormat.YUV_420_888,
                2
            )

            imageReader?.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage()
                image?.let {
                    processImage(it)
                    it.close()
                }
            }, backgroundHandler)

            cameraManager.openCamera(frontCameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    createCaptureSession()
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    cameraDevice = null
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    cameraDevice = null
                    Log.e(TAG, "Camera error: $error")
                }
            }, backgroundHandler)

        } catch (e: SecurityException) {
            Log.e(TAG, "Camera permission not granted", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening camera", e)
        }
    }

    private fun closeCamera() {
        try {
            captureSession?.close()
            captureSession = null
            cameraDevice?.close()
            cameraDevice = null
            imageReader?.close()
            imageReader = null
        } catch (e: Exception) {
            Log.e(TAG, "Error closing camera", e)
        }
    }

    private fun getFrontCameraId(cameraManager: CameraManager): String? {
        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
                return cameraId
            }
        }
        return null
    }

    private fun createCaptureSession() {
        try {
            val device = cameraDevice ?: return
            val surface = imageReader?.surface ?: return

            val captureRequestBuilder = device.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
            captureRequestBuilder.addTarget(surface)

            device.createCaptureSession(
                listOf(surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        captureSession = session
                        try {
                            session.setRepeatingRequest(
                                captureRequestBuilder.build(),
                                null,
                                backgroundHandler
                            )
                        } catch (e: Exception) {
                            Log.e(TAG, "Error starting capture", e)
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "Capture session configuration failed")
                    }
                },
                backgroundHandler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error creating capture session", e)
        }
    }

    private fun processImage(image: Image) {
        try {
            val bitmap = imageToBitmap(image)
            val mirroredAndRotated = fixOrientation(bitmap)

            val mpImage = BitmapImageBuilder(mirroredAndRotated).build()
            val timestamp = System.currentTimeMillis()

            val result = handLandmarker?.detectForVideo(mpImage, timestamp)
            result?.let { processLandmarkerResult(it) }

        } catch (e: Exception) {
            Log.e(TAG, "Error processing image", e)
        }
    }

    private fun imageToBitmap(image: Image): Bitmap {
        val planes = image.planes
        val yBuffer = planes[0].buffer
        val uBuffer = planes[1].buffer
        val vBuffer = planes[2].buffer

        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()

        val nv21 = ByteArray(ySize + uSize + vSize)
        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)

        val yuvImage = android.graphics.YuvImage(
            nv21,
            ImageFormat.NV21,
            image.width,
            image.height,
            null
        )

        val out = java.io.ByteArrayOutputStream()
        yuvImage.compressToJpeg(
            android.graphics.Rect(0, 0, image.width, image.height),
            100,
            out
        )

        val imageBytes = out.toByteArray()
        return android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    private fun fixOrientation(bitmap: Bitmap): Bitmap {
        val matrix = Matrix().apply {
            // Front camera is typically rotated 270 degrees on Android
            postRotate(270f)
        }
        val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        
        // Mirror the image horizontally
        val mirrorMatrix = Matrix().apply {
            postScale(-1f, 1f, rotatedBitmap.width / 2f, rotatedBitmap.height / 2f)
        }
        return Bitmap.createBitmap(rotatedBitmap, 0, 0, rotatedBitmap.width, rotatedBitmap.height, mirrorMatrix, true)
    }

    private fun processLandmarkerResult(result: HandLandmarkerResult) {
        if (result.landmarks().isEmpty()) {
            return
        }

        val landmarks = result.landmarks()[0]
        val landmarksList = mutableListOf<Map<String, Any>>()

        for ((index, landmark) in landmarks.withIndex()) {
            landmarksList.add(
                mapOf(
                    "id" to index,
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z()
                )
            )
        }

        landmarksCallback?.invoke(landmarksList)
    }

    fun close() {
        stopTracking()
        handLandmarker?.close()
        handLandmarker = null
    }
}
