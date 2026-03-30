package com.fingertip.app

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.os.Build
import android.util.DisplayMetrics
import android.view.View
import android.view.WindowManager

object CursorOverlayService {
    private var cursorView: CursorView? = null
    private var windowManager: WindowManager? = null
    private var isShowing = false

    fun showCursor(context: Context) {
        if (isShowing) return

        try {
            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            cursorView = CursorView(context)

            val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            )

            // VERY IMPORTANT: By default WindowManager anchors to the center of the screen
            // If we don't set Gravity to TOP and LEFT, (0,0) will be in the middle of the screen!
            params.gravity = android.view.Gravity.TOP or android.view.Gravity.LEFT

            windowManager?.addView(cursorView, params)
            isShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun hideCursor(context: Context) {
        if (!isShowing) return

        try {
            cursorView?.let { view ->
                windowManager?.removeView(view)
            }
            cursorView = null
            windowManager = null
            isShowing = false
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun updateCursorPosition(context: Context, x: Float, y: Float) {
        if (!isShowing) return

        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val displayMetrics = DisplayMetrics()
            wm.defaultDisplay.getRealMetrics(displayMetrics)

            val pixelX = (x * displayMetrics.widthPixels).toInt()
            val pixelY = (y * displayMetrics.heightPixels).toInt()

            cursorView?.let { view ->
                val params = view.layoutParams as WindowManager.LayoutParams
                params.x = pixelX - 25 // Center the cursor
                params.y = pixelY - 25
                windowManager?.updateViewLayout(view, params)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private class CursorView(context: Context) : View(context) {
        private val paint = Paint().apply {
            color = Color.parseColor("#4CAF50")
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        private val borderPaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.STROKE
            strokeWidth = 3f
            isAntiAlias = true
        }

        init {
            setBackgroundColor(Color.TRANSPARENT)
        }

        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            setMeasuredDimension(50, 50)
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val centerX = width / 2f
            val centerY = height / 2f
            val radius = 20f

            // Draw outer white border
            canvas.drawCircle(centerX, centerY, radius, borderPaint)
            // Draw inner colored circle
            canvas.drawCircle(centerX, centerY, radius - 2, paint)
            // Draw center dot
            paint.color = Color.WHITE
            canvas.drawCircle(centerX, centerY, 5f, paint)
            paint.color = Color.parseColor("#4CAF50")
        }
    }
}
