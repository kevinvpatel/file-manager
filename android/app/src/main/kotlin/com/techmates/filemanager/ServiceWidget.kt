package com.techmates.filemanager

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.widget.*
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.graphics.Color


class ServiceWidget : RemoteViewsService() {

        override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
                return StackRemoteViewsFactory(applicationContext, intent)
        }
}

class StackRemoteViewsFactory(context: Context, intent: Intent) : RemoteViewsService.RemoteViewsFactory {

        private var mContext: Context = context

        var jsonFileName: List<String>? = null
        var jsonTitle: List<String>? = null
        var jsonDate: List<String>? = null

        var date: String? = ""
        var time: String? = ""

        var fileName: String? = null
        var title: String? = null
        var filedate: String? = null


        override fun onCreate() {

        }

        override fun onDataSetChanged() {

                val prefs: SharedPreferences = mContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

                fileName = prefs.getString("reminder_fileName", null)
                title = prefs.getString("reminder_title", null)
                filedate = prefs.getString("reminder_date", null)

                println("  ")
                println("fileName -> $fileName")

                jsonFileName = fileName!!.replace("[", "").replace("]", "").split(", ")

                jsonTitle = title!!.replace("[", "").replace("]", "").split(", ")

                jsonDate = filedate!!.replace("[", "").replace("]", "").replace("M, ", "M , ").split(" , ")

                println("jsonFileName1 -> $jsonFileName")
                println("jsonTitle1 -> $jsonTitle")
                println("jsonDate1 -> $jsonDate")
                println("jsonDate!!.contains([]) -> ${jsonDate!!.contains("[]")}")
                println("jsonDate!!.contains() -> ${jsonDate!!.contains("")}")
        }

        override fun onDestroy() {

        }

        override fun getCount(): Int {
                return if(jsonDate!!.contains("")) {
                        println("jsonFileName.size Empty-> $jsonFileName")
                        0
                } else {
                        println("jsonFileName.size NotEmpty-> $jsonFileName")
                        jsonFileName!!.size
                }
        }

        override fun getViewAt(position: Int): RemoteViews {

                val rv = RemoteViews(mContext.packageName, R.layout.listview_item)
                rv.setTextViewText(R.id.reminder_name_label, jsonTitle!![position])
                if(jsonFileName!![position] == "null") {
                        rv.setTextViewText(R.id.file_name_label, "")
                } else {
                        rv.setTextViewText(R.id.file_name_label, jsonFileName!![position])
                }

                println("jsonFileName -> $jsonFileName")
                println("is jsonDate Empty? 2-> ${jsonDate == null}")

                if(jsonDate != null) {
                        date = jsonDate!![position].split(" |")[0]
                        time = jsonDate!![position].split("|")[1]

                        rv.setTextColor(R.id.Mon, Color.GRAY)
                        rv.setTextColor(R.id.Tue, Color.GRAY)
                        rv.setTextColor(R.id.Wed, Color.GRAY)
                        rv.setTextColor(R.id.Thu, Color.GRAY)
                        rv.setTextColor(R.id.Fri, Color.GRAY)
                        rv.setTextColor(R.id.Sat, Color.GRAY)
                        rv.setTextColor(R.id.Sun, Color.GRAY)

                        if(date!!.contains("Every")) {
                                rv.setTextViewText(R.id.Mon, "M  ")
                                rv.setTextViewText(R.id.Tue, "T  ")
                                rv.setTextViewText(R.id.Wed, "W  ")
                                rv.setTextViewText(R.id.Thu, "T  ")
                                rv.setTextViewText(R.id.Fri, "F  ")
                                rv.setTextViewText(R.id.Sat, "S  ")
                                rv.setTextViewText(R.id.Sun, "S")
                                rv.setTextViewText(R.id.reminder_date_label, "")

                                if(date!!.contains("Every Monday")) {
                                        rv.setTextColor(R.id.Mon, Color.BLUE)
                                }
                                if(date!!.contains("Every Tuesday")) {
                                        rv.setTextColor(R.id.Tue, Color.BLUE)
                                }
                                if(date!!.contains("Every Wednesday")) {
                                        rv.setTextColor(R.id.Wed, Color.BLUE)
                                }
                                if(date!!.contains("Every Thursday")) {
                                        rv.setTextColor(R.id.Thu, Color.BLUE)
                                }
                                if(date!!.contains("Every Friday")) {
                                        rv.setTextColor(R.id.Fri, Color.BLUE)
                                }
                                if(date!!.contains("Every Saturday")) {
                                        rv.setTextColor(R.id.Sat, Color.BLUE)
                                }
                                if(date!!.contains("Every Sunday")) {
                                        rv.setTextColor(R.id.Sun, Color.BLUE)
                                }
                        }

                        if(!date!!.contains("Every")) {
                                rv.setTextViewText(R.id.Mon, "")
                                rv.setTextViewText(R.id.Tue, "")
                                rv.setTextViewText(R.id.Wed, "")
                                rv.setTextViewText(R.id.Thu, "")
                                rv.setTextViewText(R.id.Fri, "")
                                rv.setTextViewText(R.id.Sat, "")
                                rv.setTextViewText(R.id.Sun, "")
                                rv.setTextViewText(R.id.reminder_date_label, date)
                        }

                        rv.setTextViewText(R.id.reminder_time_label, "| $time")
                }

//                val pendingListIntent = HomeWidgetLaunchIntent.getActivity(
//                        mContext,
//                        MainActivity::class.java,
//                        Uri.parse("filemanagerApp://openReminderList")
//                )
//                rv.setOnClickPendingIntent(R.id.widget_container_main, pendingListIntent)

                return rv
        }

        override fun getLoadingView(): RemoteViews? {
                return null
        }

        override fun getViewTypeCount(): Int {
                return 1
        }

        override fun getItemId(position: Int): Long {
                return position.toLong()
        }

        override fun hasStableIds(): Boolean {
                return true
        }
}
