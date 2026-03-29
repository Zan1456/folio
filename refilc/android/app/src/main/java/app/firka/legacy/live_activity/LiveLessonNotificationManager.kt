package app.zan1456.folio.live_activity

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import app.zan1456.folio.MainActivity
import app.zan1456.folio.R
import io.github.d4viddf.hyperisland_kit.HyperIslandNotification

class LiveLessonNotificationManager(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "live_lesson_activity"
        const val NOTIFICATION_ID = 1337
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Jelenlegi óra",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Az éppen folyó óra élő értesítése"
                enableVibration(false)
                setSound(null, null)
                setShowBadge(false)
            }
            notificationManager().createNotificationChannel(channel)
        }
    }

    fun showOrUpdateNative(title: String, body: String, subText: String?) {
        val pendingIntent = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)

        if (!subText.isNullOrBlank()) {
            builder.setSubText(subText)
        }

        notificationManager().notify(NOTIFICATION_ID, builder.build())
    }

    fun showOrUpdateHyperOs(title: String, body: String, subText: String?, remainingSeconds: Int) {
        // HyperIsland-ToolKit requires API 26+; fall back on older devices
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            showOrUpdateNative(title, body, subText)
            return
        }
        try {
            val pendingIntent = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val now = System.currentTimeMillis()
            val baseTime = now + (remainingSeconds * 1000L)

            val bigIslandText = if (body.isNotBlank()) "$title • $body" else title

            val hiBuilder = HyperIslandNotification.Builder(context, CHANNEL_ID, bigIslandText)
                .setEnableFloat(false)
                .setIslandFirstFloat(false)
                .setChatInfo(
                    title = bigIslandText,
                    content = "",
                    timer = io.github.d4viddf.hyperisland_kit.models.TimerInfo(-1, baseTime, remainingSeconds * 1000L, now),
                    pictureKey = "",
                    actionKeys = emptyList()
                )
                .setBigIslandCountdown(baseTime, bigIslandText)
                .setSmallIsland(title)

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(true)
                .setWhen(baseTime)
                .setUsesChronometer(true)
                .apply { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) setChronometerCountDown(true) }
                .setSilent(true)
                .setOnlyAlertOnce(true)
                .setContentIntent(pendingIntent)
                .apply { if (!subText.isNullOrBlank()) setSubText(subText) }
                .addExtras(hiBuilder.buildResourceBundle())
                .build()

            notification.extras.putString("miui.focus.param", hiBuilder.buildJsonParam())
            notificationManager().notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            // HyperOS not available – fall back to native notification
            showOrUpdateNative(title, body, subText)
        }
    }

    fun cancel() {
        notificationManager().cancel(NOTIFICATION_ID)
    }

    private fun notificationManager(): NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
}
