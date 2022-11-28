import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:filemanager_app/Screens/home_screen/home_screen.dart';
import 'package:filemanager_app/Screens/reminder_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class Reminder_List_Screen extends StatefulWidget {
  const Reminder_List_Screen({Key? key}) : super(key: key);

  @override
  _Reminder_List_ScreenState createState() => _Reminder_List_ScreenState();
}

class _Reminder_List_ScreenState extends State<Reminder_List_Screen> {

  DB db = DB();

  List<NotificationFile> lstNotificationFile = [];
  Future getAllNotificationFile() async {
    lstNotificationFile = await db.getAllNotificationFileData();
  }

  Widget topHeader(Size screenSize, String title, String Desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white,
            child: Icon(CupertinoIcons.bell_fill, color: Colors.black,),
          ),
          SizedBox(width: 15),
          Container(
            width: screenSize.width * 0.73,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(Desc,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget button(Size screenSize, String title, Color? color, Function() onTap) {
    return SizedBox(
      height: 40,
      width: screenSize.width * 0.45,
      child: TextButton(
        onPressed: onTap,
        child: Text(title, style: TextStyle(color: color),),
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen((uri) => getAllNotificationFile());
    getAllNotificationFile();
    setState(() { });
  }


  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          return false;
        },
        child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(onPressed: () => setState(() {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          }), icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.white,)),
          title: Text('Reminder List'),
        ),
        body: FutureBuilder(
            future: getAllNotificationFile(),
            builder: (context, snapshot) {
              switch(snapshot.connectionState) {
                case ConnectionState.none:
                  return Center(child: Text('No Notification Available.', style: TextStyle(color: Colors.grey.shade200)),);
                case ConnectionState.waiting:
                  return Center(child: CircularProgressIndicator(),);
                case ConnectionState.active:
                  return SizedBox.shrink();
                case ConnectionState.done:
                  if(snapshot.hasError) {
                    return Center(child: Text('Something Wrong', style: TextStyle(color: Colors.grey.shade200)),);
                  } else {
                    return lstNotificationFile.isEmpty == true ? Center(child: Text('No reminders available', style: TextStyle(color: Colors.grey.shade200)),) :
                    ListView.builder(
                        padding: const EdgeInsets.only(top: 5, bottom: 5),
                        physics: const BouncingScrollPhysics(),
                        itemCount: lstNotificationFile.length,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {

                          var reminder = lstNotificationFile[index];

                          return Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.all(Radius.circular(20))
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //Header
                                    topHeader(screenSize, reminder.title, reminder.description!),
                                    Divider(height: 0, thickness: 0.5),
                                    //Middle
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          reminder.fileName != null ?
                                            Text(reminder.isFile == 1 ? 'Filename : ${reminder.fileName}' : 'Folder : ${reminder.fileName}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300))
                                              : SizedBox.shrink(),
                                          reminder.fileName != null ? SizedBox(height: 10) : SizedBox.shrink(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              !reminder.dateTime.contains('Every')
                                                  ? Expanded(child: Text(reminder.dateTime, style: TextStyle(fontWeight: FontWeight.w300),textAlign: TextAlign.end),)
                                                  : Row(
                                                    children: [
                                                      Text('M  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Monday') ? Colors.blueAccent : Colors.white)),
                                                      Text('T  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Tuesday') ? Colors.blueAccent : Colors.white)),
                                                      Text('W  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Wednesday') ? Colors.blueAccent : Colors.white)),
                                                      Text('T  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Thursday') ? Colors.blueAccent : Colors.white)),
                                                      Text('F  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Friday') ? Colors.blueAccent : Colors.white)),
                                                      Text('S  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Saturday') ? Colors.blueAccent : Colors.white)),
                                                      Text('S  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: reminder.dateTime.contains('Every Sunday') ? Colors.blueAccent : Colors.white)),
                                                      Text(' | ' + reminder.dateTime.split('|').last, style: TextStyle(fontWeight: FontWeight.w300),textAlign: TextAlign.end),
                                                    ],
                                                  )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Divider(height: 0, thickness: 0.5),
                                    //Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        button(screenSize, 'EDIT', Colors.blue, (){
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
                                              ReminderScreen(
                                                fileId: reminder.fileId,
                                                fileName: reminder.fileName,
                                                title: reminder.title,
                                                description: reminder.description,
                                                dateTime: reminder.dateTime,
                                                uid: reminder.notificationId,
                                                isUpdate: true,
                                                isFile: reminder.isFile,
                                                filePath: reminder.filePath,
                                              )
                                          ));
                                        }),
                                        Container(
                                          color: Colors.grey.shade600,
                                          width: 0.3,
                                          height: 40,
                                        ),
                                        button(screenSize, 'DELETE', Colors.red.shade700, () async {

                                          await AwesomeNotifications().cancelSchedule(int.parse(reminder.notificationId));

                                          await db.deleteNotificationFileData(reminder.fileId!).then((value) async {
                                            late List<String?> arrFileName = [];
                                            late List<String> arrTitle = [];
                                            late List<String> arrDate = [];

                                            await db.getAllNotificationFileData().then((notification) {
                                                notification.forEach((element) {
                                                  arrFileName.add(element.fileName);
                                                  arrTitle.add(element.title);
                                                  arrDate.add(element.dateTime);
                                                });
                                            });
                                            print('lstNotificationFile.toString()22 -> ${arrFileName}');
                                            await HomeWidget.saveWidgetData('reminder_fileName', arrFileName.toString());
                                            await HomeWidget.saveWidgetData('reminder_title', arrTitle.toString());
                                            await HomeWidget.saveWidgetData('reminder_date', arrDate.toString());
                                            await HomeWidget.updateWidget(
                                                name: 'WidgetProvider',
                                                iOSName: 'WidgetProvider'
                                            );

                                          });
                                          setState(() {
                                            print('reminder.fileId -> ${reminder.fileId!}');
                                          });
                                        })
                                      ],
                                    ),
                                  ],
                                ),
                              )
                          );
                        }
                    );
                  }
              }
            }
        )
    ),
    );
  }
}
