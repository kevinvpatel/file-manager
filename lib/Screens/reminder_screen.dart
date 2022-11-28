import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:filemanager_app/Global/global.dart';
import 'package:filemanager_app/Global/global_widgets.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:filemanager_app/Screens/home_screen/home_screen.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ReminderScreen extends StatefulWidget {

  final int? fileId;
  final String? fileName;
  final String? filePath;
  final String? title;
  final String? description;
  final String? dateTime;
  final String? uid;
  final bool isUpdate;
  final int? isFile;

  const ReminderScreen({
    Key? key,
    this.fileName,
    this.title,
    this.description,
    this.dateTime,
    this.uid,
    required this.isUpdate,
    this.fileId,
    this.isFile,
    this.filePath,
  }) : super(key: key);

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {

  final GlobalKey<ScaffoldState> _reminderState = GlobalKey<ScaffoldState>();
  final TextEditingController _txtTitle = TextEditingController();
  final TextEditingController _txtDescription = TextEditingController();
  final TextEditingController _txtDate = TextEditingController();
  final TextEditingController _txtTime = TextEditingController();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DB db = DB();

  double verticleSpace = 25;
  EdgeInsets space = const EdgeInsets.symmetric(vertical: 25);

  bool isRepeat = false;

  var date;
  var time;

  //To get string output from TimeOfDay
  String formatTimeOfDay(TimeOfDay tod) {
    final now = new DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();  //"6:00 AM"
    return format.format(dt);
  }

  //TextFields
  titleField() {
    return TextFormField(
      controller: _txtTitle,
      decoration: InputDecoration(
        hintText: "Title",
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        fillColor: Colors.white.withOpacity(0.18),
        filled: true,
        border: OutlineInputBorder(
          borderSide: new BorderSide(width: 0.0, style: BorderStyle.none),
        ),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  descriptionField() {
    return TextFormField(
      controller: _txtDescription,
      decoration: InputDecoration(
        hintText: "Description",
        helperText: "(Optional*)",
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        fillColor: Colors.white.withOpacity(0.18),
        filled: true,
        border: OutlineInputBorder(
          borderSide: new BorderSide(width: 0.0, style: BorderStyle.none),
        ),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  dateField(Size screenSize) {
    return TextFormField(
      readOnly: true,
      controller: _txtDate,
      onTap: () async {
        date = await showRoundedDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 1)),
          lastDate: DateTime(DateTime.now().year + 10),
          borderRadius: 12,
          theme: ThemeData.dark(),
          styleDatePicker: MaterialRoundedDatePickerStyle(
              paddingMonthHeader: EdgeInsets.symmetric(vertical: 12)
          ),
          height: screenSize.height * 0.4,
        );

        setState(() {
          var strFormatted = DateFormat('dd-MM-yyyy').format(date);

          if(date.toString() != 'null'){
            _txtDate.text = strFormatted;
          } else {
            _txtDate.clear();
          }
        });
      },
      decoration: InputDecoration(
          hintText: "Select Date",
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          fillColor: Colors.white.withOpacity(0.18),
          filled: true,
          border: OutlineInputBorder(
            borderSide: new BorderSide(width: 0.0, style: BorderStyle.none),
          ),
          suffixIcon: IconButton(
              onPressed: () async {
                date = await showRoundedDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(Duration(days: 1)),
                  lastDate: DateTime(DateTime.now().year + 10),
                  borderRadius: 12,
                  theme: ThemeData.dark(),
                  styleDatePicker: MaterialRoundedDatePickerStyle(
                      paddingMonthHeader: EdgeInsets.symmetric(vertical: 12)
                  ),
                  height: screenSize.height * 0.4,
                );

                setState(() {
                  var strFormatted = DateFormat('dd-MM-yyyy').format(date);

                  if(date.toString() != 'null'){
                    _txtDate.text = strFormatted;
                  } else {
                    _txtDate.clear();
                  }
                });
              },
              icon: Icon(CupertinoIcons.calendar_badge_plus)
          )
      ),
    );
  }

  chooseTime() async {
    time = await showRoundedTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      theme: ThemeData.dark(),
      borderRadius: 12,
    );

    setState(() {

      if(time.toString() != 'null'){
        var timeFormatted = formatTimeOfDay(time);
        _txtTime.text = timeFormatted;
      } else {
        _txtTime.clear();
      }

    });
  }

  timeField(Size screenSize) {
    return TextFormField(
      readOnly: true,
      controller: _txtTime,
      onTap: chooseTime,
      decoration: InputDecoration(
          hintText: "Select Time",
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          fillColor: Colors.white.withOpacity(0.18),
          filled: true,
          border: OutlineInputBorder(
            borderSide: new BorderSide(width: 0.0, style: BorderStyle.none),
          ),
          suffixIcon: IconButton(
              onPressed: chooseTime,
              icon: Icon(CupertinoIcons.time)
          )
      ),
    );
  }


  alert(String msg){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Attention!'),
          content: Text(msg, style: TextStyle(fontSize: 16),),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: const Text("OK", style: TextStyle(fontSize: 15),)
            )
          ],
        );
      },
    );
  }

  late SharedPreferences _prefs;
  late DateTime finalDate_Time;

  //use workmanager to execute task when app is in background and killed

  //Buttons
  setButton(CoreNotifier coreNotifier) {
    return ElevatedButton(
      onPressed: () async {
        print('Pressed btn');
        _prefs = await SharedPreferences.getInstance();

        if(_prefs.getInt('lastNotificationId') == null){
          if(uid == null){
            uid = 0;
          }
        } else {
          uid = _prefs.getInt('lastNotificationId')!;
        }

        var dateTime;

        if(_txtTitle.text.isEmpty) {
          alert('Please choose Title');
        } else if(_txtDate.text.isEmpty) {

          //if repeat empty
          if(lstselected_days.isEmpty) {
            alert('Please choose Starting Date');
          } else if(selectedDays.isEmpty) {
            alert('Please choose Starting Date');
          } else {
            // alert('Please choose Starting Date');

            var days = selectedDays.join(', ');
            dateTime = days + ' | ' + _txtTime.text;

            //Update notification data in local data
            await db.updateNotificationFileData(NotificationFile(
                fileId: widget.fileId,
                fileName: widget.fileName,
                title: _txtTitle.text,
                description: _txtDescription.text,
                notificationId: widget.uid!.toString(),
                dateTime: dateTime,
                isFile: widget.isFile,
                isComplete: 0,
                filePath: widget.filePath
            ));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          }

        } else if(_txtTime.text.isEmpty) {
          alert('Please choose Time');
        } else {

          try {
            String strDateTime = _txtDate.text + ' ' + _txtTime.text;
            DateTime finalDateTime = new DateFormat('dd-MM-yyyy HH:mm aaa').parse(strDateTime);
            DateTime? finalDateTime11 = DateTime.tryParse(strDateTime);

            if(widget.isUpdate == true) {
              int notificationId = int.parse(widget.uid!);
              await AwesomeNotifications().cancel(notificationId);
              await db.deleteNotificationFileData(widget.fileId!);
            }

              print('Notification Repeat strDateTime 11-> $strDateTime');
              print('Notification Repeat finalDateTime 11-> $finalDateTime');
              print('Notification Repeat finalDateTime QQ-> $finalDateTime11');
            if(selectedDaysInNum.isNotEmpty) {
              var daysCode = selectedDays.join(", ");
              dateTime = daysCode + " | " + _txtTime.text;
              print('Notification Repeat dateTime -> $dateTime');
              print('Notification Repeat finalDateTime 22-> $finalDateTime');

              selectedDaysInNum.forEach((weekDay) async {
                await AwesomeNotifications().createNotification(
                    content: NotificationContent(
                        id: createUniqueId(),
                        channelKey: 'reminder',
                        title: _txtTitle.text,
                        body: _txtDescription.text,
                        createdDate: DateTime.now().toString(),
                        summary: widget.filePath,
                        notificationLayout: NotificationLayout.Inbox,
                        displayOnForeground: true,
                        displayOnBackground: true,
                        ticker: 'Akshar note reminder'
                    ),
                    schedule: NotificationCalendar(
                        weekday: weekDay,
                        hour: finalDateTime.hour,
                        minute: finalDateTime.minute,
                        second: 0,
                        millisecond: 0
                    )
                ).then((value) {

                  print("createUniqueId() -> ${createUniqueId()}");
                  print("weekDay -> $weekDay");
                  print("finalDateTime.hour -> ${finalDateTime.hour}");
                  print("finalDateTime.minute -> ${finalDateTime.minute}");
                });

              });
            } else {
              dateTime = _txtDate.text + " | " + _txtTime.text;

              await AwesomeNotifications().createNotification(
                  content: NotificationContent(
                      id: createUniqueId(),
                      channelKey: 'reminder',
                      title: _txtTitle.text,
                      body: _txtDescription.text,
                      createdDate: DateTime.now().toString(),
                      summary: widget.filePath,
                      notificationLayout: NotificationLayout.Inbox,
                      displayOnForeground: true,
                      displayOnBackground: true,
                      ticker: 'Akshar note reminder'
                  ),
                  schedule: NotificationCalendar(
                      year: finalDateTime.year,
                      month: finalDateTime.month,
                      day: finalDateTime.day,
                      hour: finalDateTime.hour,
                      minute: finalDateTime.minute,
                      second: 0,
                      millisecond: 0
                  )
              ).then((value) {

                print("finalDateTime.month -> ${finalDateTime.month}");
                print("finalDateTime.day -> ${finalDateTime.day}");
                print("finalDateTime.hour -> ${finalDateTime.hour}");
                print("finalDateTime.minute -> ${finalDateTime.minute}");
              });
            }

            db.insertNotificationFileData(NotificationFile(
                fileName: widget.fileName,
                title: _txtTitle.text,
                description: _txtDescription.text,
                dateTime: dateTime,
                notificationId: createUniqueId().toString(),
                isFile: widget.isFile,
                isComplete: 0,
                filePath: widget.filePath
            )).whenComplete(() => notificationDataToWidget());

            Navigator.pop(context);
            if(!widget.isUpdate) {toast('Reminder set successfully');} else {toast('Reminder update successfully');}

          } catch(e) {
            print('setReminder error -> $e');

          }
        }

      },
      child: const Text("SET", style: TextStyle(color: Colors.white, fontSize: 15),),
    );
  }

  //Creates new unique id everytime
  int createUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  // selectDays(List<Object?> selectedDays, int uid) {
  //   notiId.clear();
  //
  //   DateTime today = DateTime.now();
  //   selectedDays.forEach((day) async {
  //     switch(day){
  //       case 'Every Sunday':
  //         int j = 7;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //       case 'Every Monday':
  //         int j = 1;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //       case 'Every Tuesday':
  //         int j = 2;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //       case 'Every Wednesday':
  //         int j = 3;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //       case 'Every Thursday':
  //         int j = 4;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //       case 'Every Friday':
  //         int j = 5;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //       case 'Every Saturday':
  //         int j = 6;
  //         for (int i=0; i<20; i++){
  //           DateTime _firstDayOfTheweek = today.subtract(new Duration(days: today.weekday - j));
  //           j = j + 7;
  //
  //           var strDate = DateFormat('dd-MM-yyyy').format(_firstDayOfTheweek);
  //           var finalDate = strDate + ' ' + _txtTime.text;
  //           finalDate_Time = new DateFormat('dd-MM-yyyy HH:mm a').parse(finalDate);
  //
  //           uid = uid + 1;
  //           notiId.add(uid);
  //           await AwesomeNotifications().createNotification(
  //               content: NotificationContent(
  //                   id: uid,
  //                   channelKey: 'reminder',
  //                   title: _txtTitle.text,
  //                   body: _txtDescription.text,
  //                   createdDate: DateTime.now().toString(),
  //                   summary: widget.filePath,
  //                   notificationLayout: NotificationLayout.BigText,
  //                   displayOnForeground: true,
  //                   displayOnBackground: true,
  //                   ticker: 'Akshar note reminder'
  //               ),
  //               schedule: NotificationCalendar.fromDate(date: finalDate_Time)
  //           );
  //         }
  //         break;
  //     }
  //   });
  //
  // }

  cancelButton(CoreNotifier coreNotifier) {
    return ElevatedButton(
      // onPressed: () => Navigator.pop(_reminderState.currentContext!),
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())).then((value) => coreNotifier.reload()),
      child: const Text("CANCEL", style: TextStyle(color: Colors.white, fontSize: 15),),
    );
  }

  List<String> lstNotifications = [];

  List<int?> selectedDaysInNum = [];
  List<String?> selectedDays = [];
  List<int> notiId = [];
  List<String> date_time = [];

  List<String> lstselected_days = [];

  //for add data into homeWidget
  late List<String?> arrFileName = [];
  late List<String> arrTitle = [];
  late List<String> arrDate = [];

  //For Save data and update to HomeScreenWidget
  Future notificationDataToWidget() async {
    await db.getAllNotificationFileData().then((notification) async {
      //Add notification data to homescreen widget
      notification.forEach((element) {
        arrFileName.add(element.fileName);
        arrTitle.add(element.title);
        arrDate.add(element.dateTime);
      });

      await HomeWidget.saveWidgetData('reminder_fileName', arrFileName.toString());
      await HomeWidget.saveWidgetData('reminder_title', arrTitle.toString());
      await HomeWidget.saveWidgetData('reminder_date', arrDate.toString());
      await HomeWidget.updateWidget(
          name: 'WidgetProvider',
          iOSName: 'WidgetProvider'
      );

      return notification;
    });

  }

  @override
  void initState() {
    super.initState();

    if(widget.isUpdate == true) {
      if(widget.title!.isNotEmpty)_txtTitle.text = widget.title!;
      if(widget.description!.isNotEmpty)_txtDescription.text = widget.description!;
      if(widget.dateTime!.isNotEmpty) {
        date_time = widget.dateTime!.split("|");
        //date_time[0] == 'Days / Date'  , date_time[1] == 'Time'
        if(date_time[0].trim()[0] == 'E') {
          _txtDate.text = '';
          date_time[0].split(',').forEach((days) {
            days.trim();
            lstselected_days.add(days.trim());
          });

        } else {
          _txtDate.text = date_time[0].trim();
        }
        _txtTime.text = date_time[1].trimLeft();
      }
    }

  }


  @override
  void dispose() {
    super.dispose();
    // AwesomeNotifications().actionSink.close();
    // AwesomeNotifications().createdSink.close();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    var coreNotifier = Provider.of<CoreNotifier>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        return true;
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black87,
          key: _reminderState,
          appBar: AppBar(
              leading: IconButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())),
                  icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.white,)
              ),
              title: const Text("Set Reminder", style: TextStyle(color: Colors.white))
          ),
          body: Container(
              height: screenSize.height,
              width: screenSize.width,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: screenSize.width * 0.9,
                            height: screenSize.width * 0.12,
                            child: titleField()
                        )
                      ],
                    ),
                    SizedBox(height: verticleSpace),
                    //Description
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: screenSize.width * 0.9,
                          height: screenSize.width * 0.22,
                          child: descriptionField(),
                        )
                      ],
                    ),
                    SizedBox(height: 12.5),
                    //Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: screenSize.width * 0.9,
                          height: screenSize.width * 0.12,
                          child: dateField(screenSize),
                        )
                      ],
                    ),
                    SizedBox(height: verticleSpace),
                    //Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: screenSize.width * 0.9,
                          height: screenSize.width * 0.12,
                          child: timeField(screenSize),
                        )
                      ],
                    ),
                    SizedBox(height: verticleSpace),
                    //DropDown
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),

                        //set new dropdown dialoge
                        child: DropdownSearch.multiSelection(
                          mode: Mode.DIALOG,
                          showSelectedItems: false,
                          items: ['Every Sunday','Every Monday','Every Tuesday','Every Wednesday','Every Thursday','Every Friday','Every Saturday'],
                          selectedItems: widget.isUpdate == true ? date_time[0].trim()[0] == 'E' ? lstselected_days : [] : [],
                          popupTitle: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                              child: Text('Repeat', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),)
                          ),
                          showAsSuffixIcons: true,
                          maxHeight: screenSize.height * 0.72,
                          dialogMaxWidth: screenSize.width * 0.72,
                          popupItemBuilder: (context, item, isSelected) {
                            return ListTile(
                              contentPadding: EdgeInsets.only(right: 30, left: 30),
                              title: Text(item.toString(), style: TextStyle(color: Colors.white),),
                              selected: isSelected,
                            );
                          },
                          validator: (item) {
                            if(item == null) {
                              selectedDays.clear();
                              selectedDaysInNum.clear();

                              //Use for loop (+7) to repeat date
                              lstselected_days.forEach((day) {
                                switch(day){
                                  case 'Every Sunday':
                                    selectedDaysInNum.add(7);
                                    selectedDays.add("Every Sunday");
                                    break;
                                  case 'Every Monday':
                                    selectedDaysInNum.add(1);
                                    selectedDays.add("Every Monday");
                                    break;
                                  case 'Every Tuesday':
                                    selectedDaysInNum.add(2);
                                    selectedDays.add("Every Tuesday");
                                    break;
                                  case 'Every Wednesday':
                                    selectedDaysInNum.add(3);
                                    selectedDays.add("Every Wednesday");
                                    break;
                                  case 'Every Thursday':
                                    selectedDaysInNum.add(4);
                                    selectedDays.add("Every Thursday");
                                    break;
                                  case 'Every Friday':
                                    selectedDaysInNum.add(5);
                                    selectedDays.add("Every Friday");
                                    break;
                                  case 'Every Saturday':
                                    selectedDaysInNum.add(6);
                                    selectedDays.add("Every Saturday");
                                    break;
                                }
                              });
                              return null;
                            } else {
                              return null;
                            }
                          },
                          autoValidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (selectedDay) {
                            selectedDays.clear();
                            selectedDaysInNum.clear();


                            //Use for loop (+7) to repeat date
                            selectedDay.forEach((day) {
                              switch(day){
                                case 'Every Sunday':
                                    selectedDaysInNum.add(7);
                                    selectedDays.add("Every Sunday");
                                  break;
                                case 'Every Monday':
                                    selectedDaysInNum.add(1);
                                    selectedDays.add("Every Monday");
                                  break;
                                case 'Every Tuesday':
                                    selectedDaysInNum.add(2);
                                    selectedDays.add("Every Tuesday");
                                  break;
                                case 'Every Wednesday':
                                    selectedDaysInNum.add(3);
                                    selectedDays.add("Every Wednesday");
                                  break;
                                case 'Every Thursday':
                                    selectedDaysInNum.add(4);
                                    selectedDays.add("Every Thursday");
                                  break;
                                case 'Every Friday':
                                    selectedDaysInNum.add(5);
                                    selectedDays.add("Every Friday");
                                  break;
                                case 'Every Saturday':
                                    selectedDaysInNum.add(6);
                                    selectedDays.add("Every Saturday");
                                  break;
                              }
                              print('selectedDay dropdown -> $day');
                            });

                              print('selectedDays.isEmpty -> ${selectedDays.isEmpty}');
                              if(selectedDays.isEmpty){
                                lstselected_days.clear();
                              }
                          },
                        )
                    ),
                    SizedBox(height: verticleSpace),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: screenSize.width * 0.35,
                            child: setButton(coreNotifier)
                        ),
                        SizedBox(
                          width: screenSize.width * 0.1,
                        ),
                        SizedBox(
                            width: screenSize.width * 0.35,
                            child: cancelButton(coreNotifier)
                        )
                      ],
                    )
                  ],
                ),
              )
          ),
        )
    );
  }

// //Prepare for notification
// String strDateTime = _txtDate.text + ' ' + _txtTime.text;
// DateTime finalDateTime = new DateFormat('dd-MM-yyyy HH:mm a').parse(strDateTime);
//
// if(selectedDays.isNotEmpty) {
//   selectDays(selectedDays, uid);
// }
// if(lstselected_days.isNotEmpty) {
//   lstselected_days.forEach((element) {
//     print('lstselected_days element -> $element');
//   });
//   selectDays(lstselected_days, uid);
// }
//
// //Time for data delete from notification list after certain time
// var difference = DateTime.now().difference(finalDateTime).inSeconds;
// var sec = difference.abs();
//
// String uniqueId;
// //Update notification
// if(widget.isUpdate == true) {
//
//   //Code for dismiss old notification
//   var lstUid = widget.uid!.split(', ');
//   lstUid.forEach((elementId) async {
//     await AwesomeNotifications().cancel(
//         int.parse(elementId));
//   });
//
//   Future.delayed(const Duration(milliseconds: 1500), () async {
//
//     //----------->  Update Reminder without file-folder  <-----------
//
//     print('lstselected_days -> $lstselected_days');
//     print('selectedDays -> $selectedDays');
//     if(selectedDays.isNotEmpty || lstselected_days.isNotEmpty) {
//       var days = selectedDays.isNotEmpty ? selectedDays.join(', ') : lstselected_days.join(', ');
//       dateTime = days + ' | ' + _txtTime.text;
//
//       // var uid = notiId.join(', ');
//       uniqueId = notiId.join(', ');
//       print('dateTime updated -> $dateTime');
//       print('uniqueId isUpdate -> $uniqueId');
//
//       //get last uid and set in SharedPreference
//       _prefs.setInt('lastNotificationId', notiId.last);
//
//       //Update notification data in local data
//       await db.updateNotificationFileData(NotificationFile(
//           fileId: widget.fileId,
//           fileName: widget.fileName,
//           title: _txtTitle.text,
//           description: _txtDescription.text,
//           notificationId: uniqueId,
//           dateTime: dateTime,
//           isFile: widget.isFile,
//           isComplete: 0,
//           filePath: widget.filePath
//       )).then((value) => getAllNotificationFile());
//
//     } else {
//
//       //delete data from notification list after duration
//       Future.delayed(Duration(seconds: sec), () async {
//         await db.deleteNotificationFileData(widget.fileId!);
//       });
//
//       await AwesomeNotifications().createNotification(
//           content: NotificationContent(
//               id: uid,
//               channelKey: 'reminder',
//               title: _txtTitle.text,
//               body: _txtDescription.text,
//               createdDate: DateTime.now().toString(),
//               summary: widget.filePath,
//               notificationLayout: NotificationLayout.Inbox,
//               displayOnForeground: true,
//               displayOnBackground: true,
//               ticker: 'Akshar note reminder'
//           ),
//           schedule: NotificationCalendar.fromDate(date: finalDateTime)
//       );
//       //get last uid and set in SharedPreference
//       print('@@last notificationId -> $uid');
//       _prefs.setInt('lastNotificationId', uid);
//
//       //Update notification data in local data
//       await db.updateNotificationFileData(NotificationFile(
//           fileId: widget.fileId,
//           fileName: widget.fileName,
//           title: _txtTitle.text,
//           description: _txtDescription.text,
//           notificationId: uid.toString(),
//           dateTime: _txtDate.text + ' | ' + _txtTime.text,
//           isFile: widget.isFile,
//           isComplete: 0,
//           filePath: widget.filePath
//       )).then((value) => getAllNotificationFile());
//     }
//
//   });
//
//   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())).then((value) => coreNotifier.reload());
//   // Navigator.pop(context, coreNotifier);
//   toast('Reminder update successfully');
//
// }
// //Create notification
// else {
//
//   Navigator.pop(_reminderState.currentContext!);
//   toast('Reminder set successfully');
//
//   String _filename = '';
//   //Only reminder Set from file-folder
//   if(widget.fileName != null) {
//     //will get all notification name from database to check if current file already store,
//     //Check for if reminder already exist.
//     Future<List<NotificationFile>> reminderData = db.getNotificationFileNameData(widget.fileName!);
//     reminderData.then((value) {
//       value.forEach((element) {
//         print('value -> ${element.fileName}');
//         print('widget.fileName -> ${widget.fileName}');
//         if(element.fileName == widget.fileName){
//           _filename = element.fileName!;
//         }
//       });
//     }).whenComplete(() async {
//       if(_filename.isEmpty) {
//         Future.delayed(Duration(seconds: 1), () async {
//           //Non-repeat date..
//           if(selectedDays.isEmpty){
//             //Generate new notification id
//             uid = uid + 1;
//
//             dateTime = _txtDate.text + ' | ' + _txtTime.text;
//             uniqueId = uid.toString();
//
//             //Code for create notification
//             await AwesomeNotifications().createNotification(
//                 content: NotificationContent(
//                     id: int.parse(uniqueId),
//                     channelKey: 'reminder',
//                     title: _txtTitle.text,
//                     body: _txtDescription.text,
//                     createdDate: DateTime.now().toString(),
//                     summary: widget.filePath,
//                     notificationLayout: NotificationLayout.BigText,
//                     displayOnForeground: true,
//                     displayOnBackground: true,
//                     ticker: 'Akshar note reminder'
//                 ),
//                 schedule: NotificationCalendar.fromDate(date: finalDateTime)
//             );
//             // notificationProvider.scheduledNotification(int.parse(uniqueId), _txtTitle.text, _txtDescription.text, widget.filePath);
//
//             //get last uid and set in SharedPreference
//             print('@@last uid -> $uid');
//             _prefs.setInt('lastNotificationId', uid);
//
//           }
//           //Repeat days..
//           else {
//             var days = selectedDays.join(', ');
//             dateTime = days + ' | ' + _txtTime.text;
//
//             // var uid = notiId.join(', ');
//             uniqueId = notiId.join(', ');
//             print('uniqueId -> $uniqueId');
//
//             //get last uid and set in SharedPreference
//             print('@@last notiId -> ${notiId.last}');
//             _prefs.setInt('lastNotificationId', notiId.last);
//
//           }
//
//           //Insert notification data in local data
//           db.insertNotificationFileData(NotificationFile(
//               fileName: widget.fileName,
//               title: _txtTitle.text,
//               description: _txtDescription.text,
//               dateTime: dateTime,
//               notificationId: uniqueId,
//               isFile: widget.isFile,
//               isComplete: 0,
//               filePath: widget.filePath
//           )).then((notification) async {
//
//             getAllNotificationFile();
//
//             var file1 = await db.getNotificationFileNameData(widget.fileName!);
//             //If repeat not choosen
//             if(selectedDays.isEmpty) {
//               //delete data from notification list after duration
//               Future.delayed(Duration(seconds: sec), () async {
//                 print('file1.last.fileId! -> ${file1.last.fileId!}');
//                 await db.deleteNotificationFileData(file1.last.fileId!);
//               });
//             }
//
//           });
//         });
//
//       } else {
//         toast('Reminder \' ${widget.fileName} \' Already Exist');
//       }
//     });
//   }
//
//   //Only reminder Without file-folder
//   else {
//     if(selectedDays.isEmpty) {
//       uid = uid + 1;
//
//       dateTime = _txtDate.text + ' | ' + _txtTime.text;
//       uniqueId = uid.toString();
//
//       //Code for create notification
//       await AwesomeNotifications().createNotification(
//           content: NotificationContent(
//               id: int.parse(uniqueId),
//               channelKey: 'reminder',
//               title: _txtTitle.text,
//               body: _txtDescription.text,
//               createdDate: DateTime.now().toString(),
//               summary: widget.filePath,
//               notificationLayout: NotificationLayout.BigText,
//               displayOnForeground: true,
//               displayOnBackground: true,
//               ticker: 'Akshar note reminder'
//           ),
//           schedule: NotificationCalendar.fromDate(date: finalDateTime)
//       );
//
//       print('@@last uid -> $uid');
//       _prefs.setInt('lastNotificationId', uid);
//
//     } else {
//
//       var days = selectedDays.join(', ');
//       dateTime = days + ' | ' + _txtTime.text;
//
//       // var uid = notiId.join(', ');
//       uniqueId = notiId.join(', ');
//       print('uniqueId -> $uniqueId');
//
//       //get last uid and set in SharedPreference
//       print('@@last notiId -> ${notiId.last}');
//       _prefs.setInt('lastNotificationId', notiId.last);
//
//     }
//
//     //Insert notification data in local data
//     db.insertNotificationFileData(NotificationFile(
//         fileName: widget.fileName,
//         title: _txtTitle.text,
//         description: _txtDescription.text,
//         dateTime: dateTime,
//         notificationId: uniqueId,
//         isFile: widget.isFile,
//         isComplete: 0,
//         filePath: widget.filePath
//     )).then((value) => getAllNotificationFile());
//
//   }
//
//   coreNotifier.reload();
// }
// try {
//   //Notification touch handling
//   AwesomeNotifications().actionStream.listen((receivedNotification) async {
//
//     if(receivedNotification.summary != null) {
//       var lstFilePath = receivedNotification.summary!.split('/');
//       lstFilePath.remove(receivedNotification.summary!.split('/').last);
//       var finalPath = lstFilePath.join('/');
//
//       if(FileSystemEntity.isDirectorySync(receivedNotification.summary!)) {
//         coreNotifier.navigateToDirectory(receivedNotification.summary!);
//       } else {
//         coreNotifier.navigateToDirectory(finalPath);
//         OpenFile.open(receivedNotification.summary!);
//       }
//     }
//   });
// } catch(e) {
//   print('notification error -> $e');
// }

}