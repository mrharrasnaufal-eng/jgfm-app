package com.jagatfilm.jagatfilm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class CustomNotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "jagatfilm_general"
        const val CHANNEL_NAME = "Notifikasi JagatFilm"

        /** Max poster dimension in px (notification row only needs a small thumbnail). */
        private const val MAX_POSTER_PX = 400
    }

    init {
        createChannel()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Info drama baru, event, dan promosi JagatFilm"
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    suspend fun show(
        id: Int,
        title: String,
        message: String,
        imageUrl: String?,
        action: String?
    ) {
        // Download poster image (if available)
        val posterBitmap = if (!imageUrl.isNullOrBlank()) {
            downloadBitmap(imageUrl)
        } else null

        // Create intent for notification tap (and button tap).
        // MainActivity reads the extra and forwards it to the pending-action prefs.
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_NOTIFICATION_ACTION, action ?: "")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Collapsed layout
        val collapsedView = RemoteViews(context.packageName, R.layout.notification_collapsed).apply {
            setTextViewText(R.id.notif_title, title)
            setTextViewText(R.id.notif_message, message)
            if (posterBitmap != null) {
                setImageViewBitmap(R.id.notif_poster, posterBitmap)
            }
            setOnClickPendingIntent(R.id.notif_button, pendingIntent)
        }

        // Expanded layout
        val expandedView = RemoteViews(context.packageName, R.layout.notification_expanded).apply {
            setTextViewText(R.id.notif_expanded_title, title)
            setTextViewText(R.id.notif_expanded_message, message)
            if (posterBitmap != null) {
                setImageViewBitmap(R.id.notif_expanded_poster, posterBitmap)
            }
            setOnClickPendingIntent(R.id.notif_expanded_button, pendingIntent)
        }

        // Build notification with custom layouts
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, notification)
    }

    private suspend fun downloadBitmap(url: String): Bitmap? {
        return withContext(Dispatchers.IO) {
            try {
                val connection = URL(url).openConnection() as HttpURLConnection
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                connection.doInput = true
                connection.connect()
                if (connection.responseCode == 200) {
                    val bytes = connection.inputStream.readBytes()
                    // Downsample: RemoteViews IPC transactions are capped at ~1MB —
                    // a full-size poster bitmap would crash with TransactionTooLargeException.
                    decodeSampledBitmap(bytes, MAX_POSTER_PX)
                } else null
            } catch (e: Exception) {
                null
            }
        }
    }

    /**
     * Decode with inSampleSize so the longest side is at most [maxSize] px.
     */
    private fun decodeSampledBitmap(bytes: ByteArray, maxSize: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= maxSize ||
            bounds.outHeight / (sample * 2) >= maxSize
        ) {
            sample *= 2
        }
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
    }
}
