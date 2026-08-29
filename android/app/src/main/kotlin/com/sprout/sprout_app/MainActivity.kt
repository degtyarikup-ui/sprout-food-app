package com.sprout.sprout_app

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sprout.sprout_app/shortcut"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pinHomeScreenShortcut()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pinShortcut") {
                pinHomeScreenShortcut()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun pinHomeScreenShortcut() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val shortcutManager = getSystemService(ShortcutManager::class.java)
                if (shortcutManager != null && shortcutManager.isRequestPinShortcutSupported) {
                    val pinIntent = Intent(applicationContext, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                    }

                    val pinShortcutInfo = ShortcutInfo.Builder(applicationContext, "sprout_desktop_shortcut")
                        .setShortLabel("Sprout")
                        .setLongLabel("Sprout — Умная Еда")
                        .setIcon(Icon.createWithResource(applicationContext, R.mipmap.ic_launcher))
                        .setIntent(pinIntent)
                        .build()

                    shortcutManager.requestPinShortcut(pinShortcutInfo, null)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
