// ignore_for_file: import_of_legacy_library_into_null_safe
import 'package:bot_toast/bot_toast.dart';
import 'package:filemanager_app/Screens/home_screen/home_screen.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/notifiers/google_sign_in_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:home_widget/home_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerBackgroundCallback((p0) => backgroundCallback(p0!));

  AwesomeNotifications().initialize(
      'resource://drawable/logo',
      [
        NotificationChannel(
          channelKey: 'upload',
          channelName: 'Google drive',
          channelDescription: 'File upload notify',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          playSound: true,
          enableLights: true,
          enableVibration: true,
          channelShowBadge: true,
          importance: NotificationImportance.High
        ),
        NotificationChannel(
            channelKey: 'reminder',
            channelName: 'file reminder',
            channelDescription: 'File reminder time',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white,
            playSound: true,
            enableLights: true,
            enableVibration: true,
            channelShowBadge: true,
            importance: NotificationImportance.Max,
        )
      ]
  );
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => CoreNotifier()),
    ChangeNotifierProvider(create: (context) => GoogleSignInProvider()),
    // ChangeNotifierProvider(create: (context) => NotificationProvider()),
  ],
  child: const MyApp(),
  ));
}


// Called when Doing Background Work initiated from Widget
Future<void> backgroundCallback(Uri uri) async {
  if (uri.host == 'openReminderList') {
    print('Open Reminder List ->>>>>');
    // Navigator.push(context, MaterialPageRoute(builder: (context) => Reminder_List_Screen()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return NeumorphicApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      title: 'File Manager',
      themeMode: ThemeMode.dark,
      theme: NeumorphicThemeData(
        baseColor: Color(0xFFFFFFFF),
        lightSource: LightSource.topLeft,
        depth: 10,
      ),
      darkTheme: NeumorphicThemeData(
        baseColor: Color(0xFF3E3E3E),
        lightSource: LightSource.topLeft,
        depth: 6,
      ),
      home: HomeScreen(),
    );
    // return MaterialApp(
    //   title: 'File Manager',
    //   debugShowCheckedModeBanner: false,
    //   theme: ThemeData(
    //     brightness: Brightness.dark,
    //     splashColor: Colors.transparent,
    //     primaryColor: Colors.black,
    //     textTheme: ThemeData.dark().textTheme
    //   ),
    //   home: const HomeScreen(),
    // );
  }
}
