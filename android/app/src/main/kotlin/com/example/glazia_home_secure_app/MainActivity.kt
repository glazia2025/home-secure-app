package com.example.glazia_home_secure_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createSecurityAlertChannel()
    }

    private fun createSecurityAlertChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channelId = "glazia_security_alerts"
        val soundUri = Uri.parse("android.resource://$packageName/raw/glazia_siren")
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            channelId,
            "Security alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Door opening and shock detection alerts"
            enableVibration(true)
            setSound(soundUri, audioAttributes)
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }
}
