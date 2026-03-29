package app.zan1456.folio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import app.zan1456.folio.live_activity.LiveLessonNotificationManager

class MainActivity : FlutterActivity() {

    private val LIVE_ACTIVITY_CHANNEL = "app.zan1456.folio/android_live_activity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val manager = LiveLessonNotificationManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_ACTIVITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showOrUpdateNative" -> {
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val subText = call.argument<String>("subText")
                        manager.showOrUpdateNative(title, body, subText)
                        result.success(null)
                    }
                    "showOrUpdateHyperOs" -> {
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        val subText = call.argument<String>("subText")
                        val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                        manager.showOrUpdateHyperOs(title, body, subText, remainingSeconds)
                        result.success(null)
                    }
                    "cancel" -> {
                        manager.cancel()
                        result.success(null)
                    }
                    "getCookies" -> {
                        val url = call.argument<String>("url") ?: ""
                        val cookieManager = android.webkit.CookieManager.getInstance()
                        val cookies = cookieManager.getCookie(url) ?: ""
                        result.success(cookies)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
