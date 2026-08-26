package com.jagatfilm.jagatfilm

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jagatfilm.jagatfilm/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showCustomNotification" -> {
                    val id = call.argument<Int>("id") ?: System.currentTimeMillis().toInt()
                    val title = call.argument<String>("title") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val imageUrl = call.argument<String>("image_url")
                    val action = call.argument<String>("action")

                    if (title.isBlank() && message.isBlank()) {
                        result.error("INVALID", "Title and message cannot both be empty", null)
                        return@setMethodCallHandler
                    }

                    val helper = CustomNotificationHelper(this@MainActivity)
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            helper.show(id, title, message, imageUrl, action)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NOTIF_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
