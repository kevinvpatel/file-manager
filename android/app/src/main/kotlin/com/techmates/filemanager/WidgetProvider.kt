package com.techmates.filemanager

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import android.content.Intent
import android.content.SharedPreferences
import android.widget.*
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context,
                        MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            }

            //Fetch data from flutter code
            val jsonFileName = widgetData.getString("reminder_fileName", null
                    ?: "No File Name Available")
            val jsonTitle = widgetData.getString("reminder_title", null ?: "No title Available")
            val jsonDate = widgetData.getString("reminder_date", null ?: "No Date Available")

            //intent will send data to another activity
            val dataIntent = Intent(context, ServiceWidget::class.java)
            dataIntent.removeExtra("lstFileName")
            dataIntent.removeExtra("lstTitle")
            dataIntent.removeExtra("date")

            //save data to bundle and then save it to intent
            val bundle = Bundle()
            bundle.putString("lstFileName", jsonFileName)
            bundle.putString("lstTitle", jsonTitle)
            bundle.putString("date", jsonDate)

            dataIntent.putExtras(bundle)
            context.startService(dataIntent)

            //Set data to widget listview
            views.setRemoteAdapter(widgetId, R.id.reminder_list, dataIntent)
            //shows this view when there is not data to store in listview
            views.setEmptyView(R.id.reminder_list, R.id.empty_text)

            //refresh Entire Widget
            appWidgetManager.updateAppWidget(widgetId, views)
            //refresh "onDataSetChanged" method
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.reminder_list)
        }
    }

}