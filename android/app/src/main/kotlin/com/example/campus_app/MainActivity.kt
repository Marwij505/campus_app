package com.example.campus_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.ActivityNotFoundException
import android.provider.CalendarContract

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "campus_app/calendar")
            .setMethodCallHandler { call, result ->
                if (call.method != "insert") {
                    result.notImplemented()
                } else {
                    val start = call.argument<Number>("start")?.toLong()
                    val end = call.argument<Number>("end")?.toLong()
                    val title = call.argument<String>("title")
                    if (start == null || end == null || title == null || end <= start) {
                        result.error("INVALID_EVENT", "Waktu acara tidak valid", null)
                    } else {
                        val intent = Intent(Intent.ACTION_INSERT).apply {
                            data = CalendarContract.Events.CONTENT_URI
                            putExtra(CalendarContract.Events.TITLE, title)
                            putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
                            putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
                            putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, call.argument<Boolean>("allDay") ?: false)
                            putExtra(CalendarContract.Events.EVENT_TIMEZONE, "Asia/Jakarta")
                            putExtra(CalendarContract.Events.DESCRIPTION, "Salinan SIAKAD. Perbarui/hapus jika jadwal berubah.")
                        }
                        try {
                            startActivity(intent)
                            result.success(true) // Form opened, not proof the user saved it.
                        } catch (_: ActivityNotFoundException) {
                            result.success(false)
                        } catch (_: SecurityException) {
                            result.success(false)
                        }
                    }
                }
            }
    }
}
