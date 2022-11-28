import 'dart:convert';
import 'dart:ui';
import 'package:filemanager_app/Global/global.dart';
import 'package:filemanager_app/Global/global_widgets.dart';
import 'package:filemanager_app/Screens/backup_screen/backup_screen.dart';
import 'package:filemanager_app/Screens/reminder_list_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/notifiers/google_sign_in_provider.dart';
import 'package:filemanager_app/utils/googledrive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDrawer extends StatelessWidget {
  final Size screenSize;
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final GoogleSignInProvider signInNotifier;
  final GlobalKey<ScaffoldState> scaffoldKey;

  MyDrawer({
    required this.screenSize,
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.signInNotifier,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    var signInNotifier = Provider.of<GoogleSignInProvider>(context);
    var coreNotifier = Provider.of<CoreNotifier>(context);
    final user = FirebaseAuth.instance.currentUser;
    var screenSize = MediaQuery.of(context).size;

    return SizedBox(
      width: screenSize.width * 0.78,
      child: Drawer(
        elevation: 12,
        child: Container(
          color: Colors.black26,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              //HEADER
              user != null ? DrawerHeader(
                  padding: EdgeInsets.zero,
                  curve: Curves.bounceIn,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
                    border: Border.all(color: Colors.grey.shade800),
                    color: Colors.black
                    // image: DecorationImage(
                    //   image: NetworkImage("https://media-cdn.tripadvisor.com/media/photo-s/1a/bc/a8/44/baps-shri-swaminarayan.jpg"),
                    //   colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                  child: UserAccountsDrawerHeader(
                      margin: EdgeInsets.zero,
                      decoration: const BoxDecoration(color: Colors.transparent),
                      currentAccountPictureSize: Size(screenSize.width * 0.17, screenSize.width * 0.17),
                      currentAccountPicture: user.photoURL != null ?
                      ClipOval(child: Image.network(user.photoURL!, fit: BoxFit.cover),)
                          : Text(user.displayName![0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),),
                      accountName: Text(user.displayName!, style: const TextStyle(color: Colors.white, fontSize: 20),),
                      accountEmail: Text(user.email!, style: const TextStyle(color: Colors.white, fontSize: 12),)
                  )
              ) :
              //if not signin...
              DrawerHeader(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
                  border: Border.all(color: Colors.grey.shade800),
                  color: Colors.black
                  // image: DecorationImage(
                  //   image: NetworkImage("https://media-cdn.tripadvisor.com/media/photo-s/1a/bc/a8/44/baps-shri-swaminarayan.jpg"),
                  //   colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.dstATop),
                  //   fit: BoxFit.cover,
                  // ),
                ),
                child: UserAccountsDrawerHeader(
                    margin: EdgeInsets.zero,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    currentAccountPictureSize: Size(screenSize.width * 0.17, screenSize.width * 0.17),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(CupertinoIcons.person, color: Colors.grey.shade800, size: 50),
                    ),
                    accountName: Text('Welcome Guest', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),),
                    accountEmail: const SizedBox.shrink()
                ),
              ),

              //Home
              _ListTile(image: "assets/drawer/home.png", name: "Home", ontap: ()=> Navigator.pop(context),),

              _ListTile(image: "assets/drawer/reminder.png", name: "Reminders", ontap: ()=>
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Reminder_List_Screen())),
              ),

              _ListTile(svgImage: "assets/drawer/backup.svg", name: "Backup / Restore", ontap: ()=>
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BackupScreen())),
              ),

              //SignOut
              user != null ? _ListTile(image: "assets/drawer/signout.png", name: "Log Out", ontap: () {
                signInNotifier.logout().then((value) => toast('Logout successfully'));
                Navigator.pop(context);
              })
                  //SignIn
                  : _ListTile(image: "assets/drawer/signin.png", name: "Signin", ontap: () {
                signInNotifier.login(context).whenComplete(() async {
                  driveFileName.clear();

                  SharedPreferences prefs = await SharedPreferences.getInstance();

                  //Store AuthHeader in SharedPrefs from google login
                  var mapAuthHeaders = Map<String, String>.from(
                      json.decode(prefs.getString("authHeaders")!));
                  print("mapAuthHeaders @ $mapAuthHeaders");

                  final authenticateClient = AuthenticateClient(mapAuthHeaders);
                  gd.DriveApi drive = gd.DriveApi(authenticateClient);
                  await drive.files.list().then((value) {
                    value.files!.forEach((element) {
                      if(!driveFileName.contains(element.name)){
                        driveFileName.add(element.name!);
                      }
                    });
                  }).whenComplete(() => coreNotifier.reload());
                });

              })
            ],
          ),
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {

  // final IconData icon;
  final String? image;
  final String? svgImage;
  final String name;
  final Function()? ontap;
  final Widget? child;
  const _ListTile({
    Key? key,
    // required this.icon,
    this.image,
    required this.name,
    this.ontap,
    this.child,
    this.svgImage
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // leading: Icon(icon, color: Colors.black, size: 24),
      leading: image == null ? SvgPicture.asset(
        svgImage!,
        height: 27,
        width: 27,
      ) : Image.asset(
        image!,
        height: 27,
        width: 27,
      ),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),textScaleFactor: 1.15,),
      onTap: ontap,
    );
  }
}
