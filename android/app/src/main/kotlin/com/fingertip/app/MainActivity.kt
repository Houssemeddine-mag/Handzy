package com.fingertip.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CAMERA_PERMISSION_CODE = 100
    private val OVERLAY_PERMISSION_CODE = 101

    private lateinit var mediaPipeHelper: MediaPipeHelper
    private var landmarksEventChannel: EventChannel? = null

    companion object {
        const val MEDIAPIPE_CHANNEL = "com.fingertip.app/mediapipe"
        const val ACCESSIBILITY_CHANNEL = "com.fingertip.app/accessibility"
        const val LANDMARKS_CHANNEL = "com.fingertip.app/landmarks"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mediaPipeHelper = MediaPipeHelper(this)

        // MediaPipe Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIAPIPE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        val success = mediaPipeHelper.initialize()
                        result.success(success)
                    }
                    "startTracking" -> {
                        mediaPipeHelper.startTracking()
                        result.success(true)
                    }
                    "stopTracking" -> {
                        mediaPipeHelper.stopTracking()
                        result.success(true)
                    }
                    "hasCameraPermission" -> {
                        result.success(hasCameraPermission())
                    }
                    "requestCameraPermission" -> {
                        requestCameraPermission()
                        result.success(true)
                    }
                    "dispose" -> {
                        mediaPipeHelper.close()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Landmarks Event Channel
        landmarksEventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LANDMARKS_CHANNEL
        )
        landmarksEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                mediaPipeHelper.setLandmarksCallback { landmarks ->
                    runOnUiThread {
                        events?.success(mapOf("landmarks" to landmarks))
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                mediaPipeHelper.setLandmarksCallback(null)
            }
        })

        // Accessibility Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "performClick" -> {
                        val x = call.argument<Double>("x") ?: 0.0
                        val y = call.argument<Double>("y") ?: 0.0
                        GestureAccessibilityService.instance?.performClick(x.toFloat(), y.toFloat())
                        result.success(true)
                    }
                    "performScroll" -> {
                        val direction = call.argument<String>("direction") ?: "up"
                        GestureAccessibilityService.instance?.performScroll(direction)
                        result.success(true)
                    }
                    "performGlobalAction" -> {
                        val action = call.argument<String>("action") ?: ""
                        GestureAccessibilityService.instance?.executeSystemAction(action)
                        result.success(true)
                    }
                    "updateCursorPosition" -> {
                        val x = call.argument<Double>("x") ?: 0.0
                        val y = call.argument<Double>("y") ?: 0.0
                        CursorOverlayService.updateCursorPosition(
                            this@MainActivity,
                            x.toFloat(),
                            y.toFloat()
                        )
                        result.success(true)
                    }
                    "hasOverlayPermission" -> {
                        result.success(hasOverlayPermission())
                    }
                    "requestOverlayPermission" -> {
                        requestOverlayPermission()
                        result.success(true)
                    }
                    "showCursorOverlay" -> {
                        CursorOverlayService.showCursor(this@MainActivity)
                        result.success(true)
                    }
                    "hideCursorOverlay" -> {
                        CursorOverlayService.hideCursor(this@MainActivity)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_CODE
        )
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_CODE)
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${packageName}/${GestureAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(service) == true
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaPipeHelper.close()
    }
}
