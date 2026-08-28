package com.jagatfilm.jagatfilm

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jagatfilm.jagatfilm/notifications"

    companion object {
        /**
         * True while the activity is visible. Used by JagatFilmMessagingService to skip
         * native display when Dart is already handling foreground messages.
         */
        @Volatile
        var isAppForeground = false

        const val EXTRA_NOTIFICATION_ACTION = "notification_action"
        const val FLUTTER_PREFS_FILE = "FlutterSharedPreferences"
        const val FLUTTER_PREFS_KEY_PENDING_ACTION = "flutter.pending_notification_action"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationExtra(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationExtra(intent)
    }

    override fun onResume() {
        super.onResume()
        isAppForeground = true
    }

    override fun onPause() {
        isAppForeground = false
        super.onPause()
    }

    /**
     * Native custom notifications launch MainActivity with a "notification_action" extra.
     * Flutter's shared_preferences stores keys in the file "FlutterSharedPreferences"
     * with a "flutter." prefix — writing there lets the existing Dart flow
     * (NotificationService.consumePendingAction → main.dart navigation) pick it up
     * unchanged, including on cold start via notification tap.
     */
    private fun handleNotificationExtra(intent: Intent?) {
        val action = intent?.getStringExtra(EXTRA_NOTIFICATION_ACTION) ?: return
        if (action.isEmpty()) return
        intent.removeExtra(EXTRA_NOTIFICATION_ACTION)
        try {
            getSharedPreferences(FLUTTER_PREFS_FILE, Context.MODE_PRIVATE)
                .edit()
                .putString(FLUTTER_PREFS_KEY_PENDING_ACTION, action)
                .apply()
        } catch (e: Exception) {
            // Notification tap handling is best-effort — never crash.
        }
    }

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
