// Generated by view binder compiler. Do not edit!
package com.techmates.filemanager.databinding;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.viewbinding.ViewBinding;
import com.techmates.filemanager.R;
import java.lang.NullPointerException;
import java.lang.Override;
import java.lang.String;

public final class ListviewItemBinding implements ViewBinding {
  @NonNull
  private final LinearLayout rootView;

  @NonNull
  public final TextView Fri;

  @NonNull
  public final TextView Mon;

  @NonNull
  public final TextView Sat;

  @NonNull
  public final TextView Sun;

  @NonNull
  public final TextView Thu;

  @NonNull
  public final TextView Tue;

  @NonNull
  public final TextView Wed;

  @NonNull
  public final TextView fileNameLabel;

  @NonNull
  public final TextView reminderDateLabel;

  @NonNull
  public final ImageView reminderIcon;

  @NonNull
  public final LinearLayout reminderIconContainer;

  @NonNull
  public final TextView reminderNameLabel;

  @NonNull
  public final TextView reminderTimeLabel;

  @NonNull
  public final LinearLayout widgetContainerDate;

  @NonNull
  public final LinearLayout widgetContainerDays;

  @NonNull
  public final LinearLayout widgetContainerMain;

  @NonNull
  public final LinearLayout widgetContainerTitle;

  private ListviewItemBinding(@NonNull LinearLayout rootView, @NonNull TextView Fri,
      @NonNull TextView Mon, @NonNull TextView Sat, @NonNull TextView Sun, @NonNull TextView Thu,
      @NonNull TextView Tue, @NonNull TextView Wed, @NonNull TextView fileNameLabel,
      @NonNull TextView reminderDateLabel, @NonNull ImageView reminderIcon,
      @NonNull LinearLayout reminderIconContainer, @NonNull TextView reminderNameLabel,
      @NonNull TextView reminderTimeLabel, @NonNull LinearLayout widgetContainerDate,
      @NonNull LinearLayout widgetContainerDays, @NonNull LinearLayout widgetContainerMain,
      @NonNull LinearLayout widgetContainerTitle) {
    this.rootView = rootView;
    this.Fri = Fri;
    this.Mon = Mon;
    this.Sat = Sat;
    this.Sun = Sun;
    this.Thu = Thu;
    this.Tue = Tue;
    this.Wed = Wed;
    this.fileNameLabel = fileNameLabel;
    this.reminderDateLabel = reminderDateLabel;
    this.reminderIcon = reminderIcon;
    this.reminderIconContainer = reminderIconContainer;
    this.reminderNameLabel = reminderNameLabel;
    this.reminderTimeLabel = reminderTimeLabel;
    this.widgetContainerDate = widgetContainerDate;
    this.widgetContainerDays = widgetContainerDays;
    this.widgetContainerMain = widgetContainerMain;
    this.widgetContainerTitle = widgetContainerTitle;
  }

  @Override
  @NonNull
  public LinearLayout getRoot() {
    return rootView;
  }

  @NonNull
  public static ListviewItemBinding inflate(@NonNull LayoutInflater inflater) {
    return inflate(inflater, null, false);
  }

  @NonNull
  public static ListviewItemBinding inflate(@NonNull LayoutInflater inflater,
      @Nullable ViewGroup parent, boolean attachToParent) {
    View root = inflater.inflate(R.layout.listview_item, parent, false);
    if (attachToParent) {
      parent.addView(root);
    }
    return bind(root);
  }

  @NonNull
  public static ListviewItemBinding bind(@NonNull View rootView) {
    // The body of this method is generated in a way you would not otherwise write.
    // This is done to optimize the compiled bytecode for size and performance.
    int id;
    missingId: {
      id = R.id.Fri;
      TextView Fri = rootView.findViewById(id);
      if (Fri == null) {
        break missingId;
      }

      id = R.id.Mon;
      TextView Mon = rootView.findViewById(id);
      if (Mon == null) {
        break missingId;
      }

      id = R.id.Sat;
      TextView Sat = rootView.findViewById(id);
      if (Sat == null) {
        break missingId;
      }

      id = R.id.Sun;
      TextView Sun = rootView.findViewById(id);
      if (Sun == null) {
        break missingId;
      }

      id = R.id.Thu;
      TextView Thu = rootView.findViewById(id);
      if (Thu == null) {
        break missingId;
      }

      id = R.id.Tue;
      TextView Tue = rootView.findViewById(id);
      if (Tue == null) {
        break missingId;
      }

      id = R.id.Wed;
      TextView Wed = rootView.findViewById(id);
      if (Wed == null) {
        break missingId;
      }

      id = R.id.file_name_label;
      TextView fileNameLabel = rootView.findViewById(id);
      if (fileNameLabel == null) {
        break missingId;
      }

      id = R.id.reminder_date_label;
      TextView reminderDateLabel = rootView.findViewById(id);
      if (reminderDateLabel == null) {
        break missingId;
      }

      id = R.id.reminder_icon;
      ImageView reminderIcon = rootView.findViewById(id);
      if (reminderIcon == null) {
        break missingId;
      }

      id = R.id.reminder_icon_container;
      LinearLayout reminderIconContainer = rootView.findViewById(id);
      if (reminderIconContainer == null) {
        break missingId;
      }

      id = R.id.reminder_name_label;
      TextView reminderNameLabel = rootView.findViewById(id);
      if (reminderNameLabel == null) {
        break missingId;
      }

      id = R.id.reminder_time_label;
      TextView reminderTimeLabel = rootView.findViewById(id);
      if (reminderTimeLabel == null) {
        break missingId;
      }

      id = R.id.widget_container_date;
      LinearLayout widgetContainerDate = rootView.findViewById(id);
      if (widgetContainerDate == null) {
        break missingId;
      }

      id = R.id.widget_container_days;
      LinearLayout widgetContainerDays = rootView.findViewById(id);
      if (widgetContainerDays == null) {
        break missingId;
      }

      LinearLayout widgetContainerMain = (LinearLayout) rootView;

      id = R.id.widget_container_title;
      LinearLayout widgetContainerTitle = rootView.findViewById(id);
      if (widgetContainerTitle == null) {
        break missingId;
      }

      return new ListviewItemBinding((LinearLayout) rootView, Fri, Mon, Sat, Sun, Thu, Tue, Wed,
          fileNameLabel, reminderDateLabel, reminderIcon, reminderIconContainer, reminderNameLabel,
          reminderTimeLabel, widgetContainerDate, widgetContainerDays, widgetContainerMain,
          widgetContainerTitle);
    }
    String missingId = rootView.getResources().getResourceName(id);
    throw new NullPointerException("Missing required view with ID: ".concat(missingId));
  }
}
