package com.jagatfilm.jagatfilm

import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Custom FCM service — replaces FlutterFirebaseMessagingService in the merged manifest
 * (see build-apk.yml). Extends FlutterFire's service so all its behavior is preserved
 * (foreground onMessage delivery to Dart, background isolate, token refresh).
 *
 * For DATA-ONLY messages (payload has no "notification" key) received while the app is
 * NOT in the foreground, we show the DramaBox-style custom notification natively.
 * This is the only way to get the custom layout while the app is closed — with a
 * notification payload the Android system would render the default style instead.
 *
 * Foreground messages are left to Dart (FCMService.onMessage) to avoid double display.
 */
class JagatFilmMessagingService : FlutterFirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Hand over to FlutterFire first: foreground onMessage / background isolate.
        super.onMessageReceived(remoteMessage)

        if (MainActivity.isAppForeground) return

        val data = remoteMessage.data
        val title = data["title"]?.takeIf { it.isNotBlank() } ?: return
        val message = data["message"]?.takeIf { it.isNotBlank() } ?: return
        val imageUrl = data["image_url"]?.takeIf { it.isNotBlank() }
        val action = data["action"]?.takeIf { it.isNotBlank() } ?: ""
        val externalUrl = data["external_url"]?.takeIf { it.isNotBlank() } ?: ""

        // Mirror the Dart payload scheme: 'page:xxx' | 'external:<url>' | '' (open app).
        val payload =
            if (action == "external" && externalUrl.isNotEmpty()) "external:$externalUrl"
            else action

        // onMessageReceived runs on the main thread — network + bitmap work goes to IO.
        // Note: goAsync() was removed in firebase-messaging 24.x; the system allows ~10s
        // for background processing. Our downloads time out at 5s, well within budget.
        val id = (remoteMessage.sentTime % 100000).toInt()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                CustomNotificationHelper(applicationContext)
                    .show(id, title, message, imageUrl, payload)
            } catch (e: Exception) {
                // Notifications are optional — never crash.
            }
        }
    }
}
