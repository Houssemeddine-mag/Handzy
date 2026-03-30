package com.fingertip.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.PixelFormat
import android.util.DisplayMetrics
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class GestureAccessibilityService : AccessibilityService() {

    private var screenWidth = 0
    private var screenHeight = 0

    companion object {
        var instance: GestureAccessibilityService? = null
        private const val TAG = "GestureAccessibility"
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this

        // Get screen dimensions
        val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getRealMetrics(displayMetrics)
        screenWidth = displayMetrics.widthPixels
        screenHeight = displayMetrics.heightPixels

        Log.d(TAG, "Service connected. Screen: ${screenWidth}x${screenHeight}")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to handle accessibility events for this service
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    /**
     * Perform a click gesture at the specified normalized coordinates
     * @param x Normalized x coordinate (0.0 to 1.0)
     * @param y Normalized y coordinate (0.0 to 1.0)
     */
    fun performClick(x: Float, y: Float) {
        try {
            // Convert normalized coordinates to screen pixels
            val pixelX = (x * screenWidth).coerceIn(0f, screenWidth.toFloat())
            val pixelY = (y * screenHeight).coerceIn(0f, screenHeight.toFloat())

            Log.d(TAG, "Performing click at ($pixelX, $pixelY)")

            val path = Path()
            path.moveTo(pixelX, pixelY)
            // A micro-movement helps ensure it registers as a tap on all Android versions
            path.lineTo(pixelX + 1f, pixelY + 1f)

            val gestureBuilder = GestureDescription.Builder()
            gestureBuilder.addStroke(
                GestureDescription.StrokeDescription(
                    path,
                    0,
                    100 // Duration in milliseconds
                )
            )

            val gesture = gestureBuilder.build()
            val callback = object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    super.onCompleted(gestureDescription)
                    Log.d(TAG, "Click gesture completed")
                }

                override fun onCancelled(gestureDescription: GestureDescription?) {
                    super.onCancelled(gestureDescription)
                    Log.w(TAG, "Click gesture cancelled")
                }
            }

            dispatchGesture(gesture, callback, null)
        } catch (e: Exception) {
            Log.e(TAG, "Error performing click", e)
        }
    }

    /**
     * Perform a scroll gesture
     * @param direction "up", "down", "left", or "right"
     */
    fun performScroll(direction: String) {
        try {
            val centerX = screenWidth / 2f
            val centerY = screenHeight / 2f

            var startX = centerX
            var endX = centerX
            var startY = centerY
            var endY = centerY

            when (direction) {
                "up" -> {
                    startY = screenHeight * 0.7f
                    endY = screenHeight * 0.3f
                }
                "down" -> {
                    startY = screenHeight * 0.3f
                    endY = screenHeight * 0.7f
                }
                "left" -> {
                    startX = screenWidth * 0.8f
                    endX = screenWidth * 0.2f
                }
                "right" -> {
                    startX = screenWidth * 0.2f
                    endX = screenWidth * 0.8f
                }
            }

            Log.d(TAG, "Performing scroll $direction from ($startX, $startY) to ($endX, $endY)")
            
            val path = Path()
            path.moveTo(startX, startY)
            path.lineTo(endX, endY)

            val gestureBuilder = GestureDescription.Builder()
            gestureBuilder.addStroke(
                GestureDescription.StrokeDescription(
                    path,
                    0,
                    300 // Duration in milliseconds
                )
            )

            val gesture = gestureBuilder.build()
            val callback = object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    super.onCompleted(gestureDescription)
                    Log.d(TAG, "Scroll gesture completed")
                }

                override fun onCancelled(gestureDescription: GestureDescription?) {
                    super.onCancelled(gestureDescription)
                    Log.w(TAG, "Scroll gesture cancelled")
                }
            }

            dispatchGesture(gesture, callback, null)
        } catch (e: Exception) {
            Log.e(TAG, "Error performing scroll", e)
        }
    }

    /**
     * Perform a system global action like BACK or RECENTS
     */
    fun executeSystemAction(actionStr: String) {
        try {
            val actionId = when (actionStr.uppercase()) {
                "BACK" -> GLOBAL_ACTION_BACK
                "RECENTS" -> GLOBAL_ACTION_RECENTS
                "HOME" -> GLOBAL_ACTION_HOME
                else -> {
                    Log.w(TAG, "Unknown global action: $actionStr")
                    return
                }
            }
            Log.d(TAG, "Executing global action: $actionStr ($actionId)")
            performGlobalAction(actionId)
        } catch (e: Exception) {
            Log.e(TAG, "Error executing global action", e)
        }
    }
}
