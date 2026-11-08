package com.gsvpoems.gsv_poems

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Home-screen widget: Gujarati date, tithi, festival and the Choghadiya
 * running now. The app stores a week of ready-made text (key "gsv_widget");
 * this provider picks today's entry and the current Choghadiya by the clock,
 * and wakes itself at the end of each Choghadiya and at midnight, so it stays
 * right without the app being opened.
 */
class GsvWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_TICK, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> refreshAll(context)
        }
    }

    override fun onDisabled(context: Context) {
        alarms(context).cancel(tickIntent(context))
    }

    companion object {
        private const val ACTION_TICK = "com.gsvpoems.gsv_poems.WIDGET_TICK"
        private const val KEY = "gsv_widget"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, GsvWidgetProvider::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        private fun alarms(context: Context) = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        private fun tickIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            7301,
            Intent(context, GsvWidgetProvider::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        private fun nextMidnight(now: Long): Long = Calendar.getInstance().apply {
            timeInMillis = now
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 5)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

        private fun qualityColor(q: String): Int = when (q) {
            "good" -> Color.parseColor("#7BE38C")
            "bad" -> Color.parseColor("#FF8A7A")
            else -> Color.parseColor("#A9C8FF")
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val now = System.currentTimeMillis()
            var nextChange = nextMidnight(now)
            val raw = HomeWidgetPlugin.getData(context).getString(KEY, null)
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val open = PendingIntent.getActivity(
                context, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )

            for (id in ids) {
                val v = RemoteViews(context.packageName, R.layout.gsv_widget)
                v.setOnClickPendingIntent(R.id.widget_root, open)
                if (raw == null) {
                    // Not filled yet: opening the app once fills it.
                    v.setTextViewText(R.id.w_day, "ૐ")
                    v.setTextViewText(R.id.w_month, "GSV Poems")
                    v.setTextViewText(R.id.w_weekday, "પંચાંગ માટે એપ એક વાર ખોલો")
                    v.setTextViewText(R.id.w_tithi, "")
                    v.setViewVisibility(R.id.w_chbox, View.GONE)
                    manager.updateAppWidget(id, v)
                    continue
                }
                try {
                    val data = JSONObject(raw)
                    val days = data.getJSONArray("days")
                    val place = data.optString("place", "")
                    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
                    val day = pickDay(days, today)
                    v.setTextViewText(R.id.w_day, day.optString("day"))
                    v.setTextViewText(R.id.w_month, day.optString("month"))
                    v.setTextViewText(R.id.w_weekday, day.optString("weekday"))
                    v.setTextViewText(R.id.w_tithi, day.optString("tithi"))
                    val fest = day.optString("festival")
                    v.setTextViewText(R.id.w_festival, "🪔 $fest")
                    v.setViewVisibility(R.id.w_festival, if (fest.isEmpty()) View.GONE else View.VISIBLE)
                    v.setTextViewText(R.id.w_sun, day.optString("sun"))

                    // The Choghadiya running now (the night ones run past midnight, so look at every day).
                    var found: JSONObject? = null
                    for (i in 0 until days.length()) {
                        val slots = days.getJSONObject(i).getJSONArray("slots")
                        for (k in 0 until slots.length()) {
                            val s = slots.getJSONObject(k)
                            if (s.getLong("s") <= now && now < s.getLong("e")) found = s
                        }
                    }
                    if (found != null) {
                        v.setViewVisibility(R.id.w_chbox, View.VISIBLE)
                        val title = found.optString("name")
                        v.setTextViewText(R.id.w_ch, if (place.isEmpty()) title else "$title ($place)")
                        v.setTextViewText(R.id.w_ch_detail, found.optString("detail"))
                        v.setInt(R.id.w_dot, "setColorFilter", qualityColor(found.optString("q")))
                        nextChange = minOf(nextChange, found.getLong("e") + 2_000)
                    } else {
                        v.setViewVisibility(R.id.w_chbox, View.GONE)
                    }
                } catch (e: Exception) {
                    v.setViewVisibility(R.id.w_chbox, View.GONE)
                }
                manager.updateAppWidget(id, v)
            }
            schedule(context, nextChange)
        }

        /** Today's entry, or the nearest one after it (the week runs out only if the app is not opened for days). */
        private fun pickDay(days: JSONArray, today: String): JSONObject {
            var later: JSONObject? = null
            for (i in 0 until days.length()) {
                val d = days.getJSONObject(i)
                val date = d.optString("date")
                if (date == today) return d
                if (date > today && later == null) later = d
            }
            return later ?: days.getJSONObject(days.length() - 1)
        }

        private fun schedule(context: Context, at: Long) {
            val am = alarms(context)
            val pi = tickIntent(context)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
                    am.setWindow(AlarmManager.RTC, at, 60_000, pi)
                } else {
                    am.setExact(AlarmManager.RTC, at, pi)
                }
            } catch (e: SecurityException) {
                am.set(AlarmManager.RTC, at, pi)
            }
        }
    }
}
