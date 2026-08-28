package com.example.coregame.core_game

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11 (API 30) and above: Set the preferred display mode to the highest refresh rate
            val display = activity.display
            if (display != null) {
                val modes = display.supportedModes
                var highestRate = 0f
                var highestModeId = 0
                for (mode in modes) {
                    if (mode.refreshRate > highestRate) {
                        highestRate = mode.refreshRate
                        highestModeId = mode.modeId
                    }
                }
                if (highestModeId != 0) {
                    val window = activity.window
                    val layoutParams = window.attributes
                    layoutParams.preferredDisplayModeId = highestModeId
                    window.attributes = layoutParams
                }
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6.0 (API 23) to Android 10: Set preferred refresh rate directly
            val window = activity.window
            val layoutParams = window.attributes
            val display = windowManager.defaultDisplay
            if (display != null) {
                val modes = display.supportedModes
                var highestRate = 0f
                for (mode in modes) {
                    if (mode.refreshRate > highestRate) {
                        highestRate = mode.refreshRate
                    }
                }
                if (highestRate > 0f) {
                    layoutParams.preferredRefreshRate = highestRate
                    window.attributes = layoutParams
                }
            }
        }
    }
}
