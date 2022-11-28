// ignore_for_file: import_of_legacy_library_into_null_safe, library_prefixes, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filemanager_app/Global/Widgets/drawer.dart';
import 'package:filemanager_app/Global/Widgets/flushbars.dart';
import 'package:filemanager_app/Screens/home_screen/widgets/folders_list_view.dart';
import 'package:filemanager_app/Screens/home_screen/widgets/folders_grid_view.dart';
import 'package:filemanager_app/Global/global.dart';
import 'package:filemanager_app/Global/global_widgets.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:filemanager_app/Screens/reminder_screen.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/notifiers/google_sign_in_provider.dart';
import 'package:filemanager_app/utils/googledrive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:google_sign_in/google_sign_in.dart' as signIn;
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';


// ignore: constant_identifier_names
enum Sorting { Type, Size, Date, Alpha, TypeDate, TypeSize }

enum Select { Selectable, NonSelectable }

// ignore: constant_identifier_names
enum View { Grid, List }

typedef IsSearchOn = void Function(bool val);
typedef IsLoggedIn = void Function(bool val);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtFolderName = TextEditingController();
  final TextEditingController _txtSearchController = TextEditingController();
  final ScrollController _controller = ScrollController();

  final drive = GoogleDrive();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _googleSignIn = signIn.GoogleSignIn.standard(scopes: [
    'email',
    gd.DriveApi.driveFileScope,
    gd.DriveApi.driveAppdataScope
  ]);
  final Flushbars _flushbars = Flushbars();

  View _view = View.List;

  //permission
  double radius = 0;
  bool isBlur = false;
  bool isUploadingFile = false;

  DB db = DB();
  String formattedDateTime = DateFormat("dd-MM-yyyy, HH:mm a").format(DateTime.now());
  String folderName = "";
  bool isSearchOn = false;
  bool isTextFieldOpen = false;

  late CoreNotifier coreNotifier;
  late GoogleSignInProvider signInNotifier;

  List<NotificationFile> lstNotificationFile = [];

  late SharedPreferences prefs;


  Future getDriveFiles() async {
    driveFileName.clear();
    await SharedPreferences.getInstance().then((prefs) async {
      //Store AuthHeader in SharedPrefs from google login
      var mapAuthHeaders = Map<String, String>.from(json.decode(prefs.getString("authHeaders")!));
      print("mapAuthHeaders 11@ $mapAuthHeaders");

      final authenticateClient = AuthenticateClient(mapAuthHeaders);
      gd.DriveApi drive1 = gd.DriveApi(authenticateClient);
      String? folderId = await drive.getFolderID(drive1);

      try {
        await drive1.files.list(spaces: 'drive', q: "'$folderId' in parents").then((gDrive) {
          print("value.files.length @ ${gDrive.files!.length}");

          gDrive.files!.forEach((element) {

            if(!driveFileName.contains(element.name)){
              driveFileName.add(element.name!);
            }
          });
        });
      } catch(e) {
        print("home screen @ $e");
        toast("Google connection timeout!! Please signin again");
        await _googleSignIn.disconnect();
        FirebaseAuth.instance.signOut();
        prefs.clear();
      }

    });
  }


  //FILES PICK AND STORE TO LOCATION
  Future<void> pickFiles(Directory currentDir, String msg, BuildContext context1) async {

    isUploadingFile = true;
    setState(() {});
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: false,
      withReadStream: true
    ).whenComplete(() {
      isUploadingFile = false;
      print('file picking complete...');
    });

    var _user = FirebaseAuth.instance.currentUser;
    prefs = await SharedPreferences.getInstance();


    if(result != null){

      showDialog(
        context: context1,
        builder: (BuildContext ctx) {
          return AlertDialog(
            content: Text("Do you want to upload file on google drive?", textAlign: TextAlign.start),
            actions: [
              TextButton(
                  onPressed: () {
                    print("current user1 @ $_user");

                    if(_user == null){
                      signInNotifier.login(ctx).whenComplete(() async {
                        // var _signin = await signInNotifier.googleSignIn.signIn();
                        if(_user != null){
                          print("_signin -> $_user");
                          Future.delayed(const Duration(seconds: 2),(){
                            drive.uploadThroughPick(result, currentDir, coreNotifier, ctx);
                          });
                        }

                      });
                    } else {
                      drive.uploadThroughPick(result, currentDir, coreNotifier, ctx);
                    }
                    Navigator.pop(context1, true);

                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text("YES", style: TextStyle(fontSize: 15),)
              ),
              TextButton(
                  onPressed: () {

                    Navigator.of(context1).pop();

                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text("NO", style: TextStyle(fontSize: 15),)
              )
            ]
          );
        }
      );

        for(PlatformFile item in result.files) {
          var filePath = currentDir.path + "/" + item.name;

          //CODES TO COPY FILE TO NEW PATH
          if (!await File(filePath).exists()) {

            File oldPath = File(item.path!);
            await oldPath.copy(filePath).whenComplete(() {
              isUploadingFile = false;
              coreNotifier.reload();
            }).then((value) {
              toast('${value.path.split('/').last} Imported successfully');
              print('file importing value -> ${value.path}');
            });

          } else {
            showDialog(
              context: context1,
              builder: (BuildContext ctx) {
                return AlertDialog(
                      title: const Text("Overwrite"),
                      content: Text("The same filename already exists, Do you want to overwrite : ${item.name}", textAlign: TextAlign.start),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("SKIP")
                        ),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);

                              isUploadingFile = true;
                              coreNotifier.delete(filePath);
                              File oldPath = File(item.path!);
                              oldPath.copy(filePath).whenComplete(() {
                                toast('${item.path!.split('/').last} Replaced successfully');
                                isUploadingFile = false;
                                coreNotifier.reload();
                              });
                            },
                            child: const Text("OVERWRITE")
                        ),
                      ]
                  );
              }
            );
          }
        }


      filePathsStoreLocally();
    } else {
      print("Didnt pick any files");
    }
    isBlur = false;
    _animationController.reverse();
  }

  dialogeBox(Directory currentDir) {
    return showAnimatedDialog(
        alignment: Alignment.center,
        context: _scaffoldKey.currentContext!,
        builder: (BuildContext dialogContext) {
          return Form(
            key: _formKey,
            child: AlertDialog(
              title: const Text("New"),
              contentPadding: const EdgeInsets.all(16),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _txtFolderName,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Folder",
                    ),
                    validator: (val){
                      if(val!.isEmpty){
                        return "Please enter folder name";
                      } else {
                        return null;
                      }
                    },
                    textCapitalization: TextCapitalization.sentences,
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      isBlur = false;
                      _animationController.reverse();
                      Navigator.pop(dialogContext);
                      setState(() {});
                    },
                    child: const Text("CANCEL")
                ),
                TextButton(
                    onPressed: () {

                      if(_formKey.currentState!.validate()){

                        coreNotifier.createFolder(_txtFolderName.text, currentDir, dialogContext).whenComplete((){
                          _txtFolderName.clear();
                        });

                        setState(() {
                          isBlur = false;
                          _animationController.reverse();
                        });

                        Navigator.pop(dialogContext);
                      } else {
                        print('Form can\'t be empty');
                      }

                    },
                    child: const Text("OK")
                )
              ],
            ),
          );
        },
        animationType: DialogTransitionType.scale,
        curve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 600)
    );
  }


  late List<String?> arrFileName = [];
  late List<String> arrTitle = [];
  late List<String> arrDate = [];
  Future getAllNotificationFile() async {

    lstNotificationFile = await db.getAllNotificationFileData().then((notification) async {
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


  //this will create fillPath textfile in database folder
  Future filePathsStoreLocally() async {
  List<String> lstPaths = [];

    Directory dir = Directory("/storage/emulated/0/Akshar Notes/media");
    //directory and sub-directories listing to store paths in file
    dir.list(recursive: true).forEach((element) {
      lstPaths.add(element.path);
    }).whenComplete(() async {

      final databasePath = "/storage/emulated/0/Akshar Notes/database";
      if(!await Directory(databasePath).exists()) {
        await Directory(databasePath).create();
      }
      File pathFile = File("$databasePath/filePaths.txt");
      await pathFile.writeAsString(lstPaths.toString());

    });

  }

  @override
  void initState() {
    super.initState();

    filePathsStoreLocally();
    getDriveFiles().whenComplete(() => coreNotifier.reload());
    getAllNotificationFile();

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Allow Notifications'),
              content: Text('Our app would like to send you notifications'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Don\'t Allow',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () => AwesomeNotifications()
                      .requestPermissionToSendNotifications()
                      .then((_) => Navigator.pop(context)),
                  child: Text(
                    'Allow',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          print('Notification Is Already Allowed');
        }
      },
    );

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    final curvedAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    coreNotifier = Provider.of<CoreNotifier>(context);
    signInNotifier = Provider.of<GoogleSignInProvider>(context);

    if(Platform.isAndroid){
      coreNotifier.checkAndroidStoragePermission();
    }
    
  }


  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size screenSize = MediaQuery.of(context).size;

    Timer(const Duration(milliseconds: 200), () {
      if(_controller.hasClients){
        _controller.jumpTo(_controller.position.maxScrollExtent);
      }
    });


    int backPressCounter = 0;
    int backPressTotal = 2;
    //for exit app
    Future<bool> _onWillPop() async {
      if(coreNotifier.currentPathAndroid.path.split("/").last == "media"){

        if (backPressCounter < 2) {
          toast("Press ${backPressTotal - backPressCounter} time to exit app");
          backPressCounter++;
          Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
            backPressCounter--;
          });
          return Future.value(false);
        } else {
          return Future.value(true);
        }

      } else {
        coreNotifier.navigateBackFolder();
        return false;
      }

    }


    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            key: _scaffoldKey,
            body: RefreshIndicator(
              onRefresh: () async {
                if(await Permission.manageExternalStorage.request().isGranted){
                  coreNotifier.reload();
                }
                setState(() {});
              },
              child: Container(
                color: Colors.black87,
                child: Stack(
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        !isTextFieldOpen ? AppBar(
                          leading: coreNotifier.currentPathAndroid.path.split("/").last == "media" ?
                          Builder(builder: (context) => IconButton(onPressed: () => _scaffoldKey.currentState!.openDrawer(), icon: Image.asset("assets/icons/menu.png", color: Colors.white, height: 16, width: 20, fit: BoxFit.fill)))
                              : IconButton(onPressed: () => coreNotifier.navigateBackFolder(), icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.white,)),
                          elevation: 0,
                          title: coreNotifier.currentPathAndroid.path.split("/").last == coreNotifier.mainFolderName ?
                          NeumorphicText(
                            coreNotifier.mainFolderName,
                            style: NeumorphicStyle(depth: 0, color: Colors.white.withOpacity(0.99), lightSource: LightSource.bottomRight, shape: NeumorphicShape.convex),
                            textStyle: NeumorphicTextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                          )
                              : Text(
                            coreNotifier.currentPathAndroid.path.split("/").last,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                            maxLines: 1,
                          ),
                          actions: [
                            IconButton(
                                onPressed: (){
                                  setState(() {
                                    _view = _view == View.List ? View.Grid : View.List;
                                  });
                                },
                                icon: Icon(_view == View.List ? CupertinoIcons.square_grid_2x2 : CupertinoIcons.square_list, color: Colors.white)
                            ),
                            IconButton(
                              icon: Icon(Icons.search, color: Colors.white,),
                              // onPressed: () => showSearch(
                              //     context: context, delegate: Search(path: widget.path)),
                              onPressed: (){
                                setState(() {
                                  isTextFieldOpen = true;
                                  _txtSearchController.clear();
                                });
                              },
                            ),
                          ],
                        )
                        //Appbar With Searchbar
                        : AppBar(
                          leading: IconButton(onPressed: () => setState(() {
                            isSearchOn = false;
                            isTextFieldOpen = false;
                          }), icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.white,)),
                          title: TextField(
                            controller: _txtSearchController,
                            //when press done in keyboard
                            onSubmitted: (str){
                              isSearchOn = true;
                            },
                            //when keyboard close
                            onChanged: (str){
                              isSearchOn = true;
                            },
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              contentPadding: const EdgeInsets.only(bottom: 0, left: 15),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(CupertinoIcons.clear, color: Colors.white, size: screenSize.width * 0.06,),
                              onPressed: (){
                                setState(() {
                                  isSearchOn = false;
                                  _txtSearchController.clear();
                                });
                              },
                            ),
                          ],
                        ),

                        Expanded(
                          child: Consumer<CoreNotifier>(
                            builder: (ctx1, model, child) => StreamBuilder<List<FileSystemEntity>>(
                              // stream: Stream.fromFuture(getFoldersByPath(model.currentPathAndroid.absolute.path)),
                              stream: isSearchOn == false ? coreNotifier.fileStream(model.currentPathAndroid.absolute.path)
                                  : coreNotifier.searchStream(coreNotifier.currentPathAndroid.absolute.path, _txtSearchController.text),
                              builder: (BuildContext ctx, AsyncSnapshot<List<FileSystemEntity>> snapshot) {

                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return const Center(child: Text('Press button to start.'));
                                  case ConnectionState.active:
                                    return const SizedBox(width: 0.0, height: 0.0);
                                  case ConnectionState.waiting:
                                    return const Center(child: Text("Please Wait.."));
                                  case ConnectionState.done:
                                    if (snapshot.error is FileSystemException) {
                                      return const Center(child: Text("Permission Denied"));
                                    } else if (snapshot.data!.isNotEmpty) {
                                      // logger.log('all path -> ${snapshot.data}');

                                      return _view == View.List ? FoldersListView(

                                        folders: snapshot.data!,
                                        scaffoldKey: _scaffoldKey,
                                        driveFileName: driveFileName,
                                        mainContext: _scaffoldKey.currentContext!,
                                        lstNotificationFile1: lstNotificationFile,

                                      ) : FoldersWidget(
                                        folders: snapshot.data!,
                                        screenSize: screenSize,
                                        scaffoldKey: _scaffoldKey,
                                        driveFileName: driveFileName,
                                        mainContext: _scaffoldKey.currentContext!,
                                        lstNotificationFile: lstNotificationFile,
                                      );
                                    } else {
                                      return Center(
                                        child: Text(coreNotifier.permissionGranted == false ? "No Folders!" : "Empty Directory!", textAlign: TextAlign.center,),
                                      );
                                    }
                                }
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                    isBlur == true ? GestureDetector(
                      onTap: () {
                        setState(() {
                          isBlur = false;
                          _animationController.reverse();
                        });
                      },
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(color: Colors.transparent),
                      ),
                    ) : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            drawer: MyDrawer(
              screenSize: screenSize,
              firebaseAuth: _auth,
              googleSignIn: _googleSignIn,
              signInNotifier: signInNotifier,
              scaffoldKey: _scaffoldKey,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionBubble(
              animation: _animation,
              onPress: () {
                setState(() {
                  if(_animationController.isCompleted){
                    isBlur = false;
                    _animationController.reverse();
                  } else {
                    isBlur = true;
                    _animationController.forward();
                  }
                });
              },
              iconColor: Colors.white,
              animatedIconData: AnimatedIcons.menu_close,
              backGroundColor: Colors.grey.shade800,
              items: <Bubble>[
                Bubble(
                    title: "Create New Folder",
                    titleStyle: const TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                    bubbleColor: Colors.grey.shade800,
                    icon: Icons.create_new_folder_outlined,
                    onPress: () async {
                      coreNotifier.checkAndroidStoragePermission();
                      SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {

                        Future<PermissionStatus> permission;
                        var devideInfo = await DeviceInfoPlugin().androidInfo;
                        var version = devideInfo.version.release;

                        //version check
                        if(version == "11") {
                          permission = Permission.manageExternalStorage.request();
                        } else {
                          permission = Permission.storage.request();
                        }

                        //if granted dialoge will open
                        if(await permission.isGranted){
                          dialogeBox(coreNotifier.currentPathAndroid);
                        }
                        //if denied will ask permission
                        else if(await permission.isDenied) {
                          if(version == "11") {
                            await Permission.manageExternalStorage.request();
                          } else {
                            await Permission.storage.request();
                          }
                        }
                        //if permenantly denied nothing will happen
                        else if(await permission.isPermanentlyDenied) {
                          isBlur = false;
                          _animationController.reverse();
                          setState(() {});
                        }

                      });
                      coreNotifier.reload();
                    }
                ),
                Bubble(
                    title: "  Choose Files   ",
                    titleStyle: const TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                    bubbleColor: Colors.grey.shade800,
                    icon: CupertinoIcons.arrow_down_doc,
                    onPress: (){
                      pickFiles(coreNotifier.currentPathAndroid, "Please wait...", context).whenComplete(() => setState((){}));
                    }
                ),
                Bubble(
                    title: "Add Reminder",
                    titleStyle: const TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                    bubbleColor: Colors.grey.shade800,
                    icon: Icons.add_alarm,
                    onPress: () {
                      isBlur = false;
                      _animationController.reverse();
                      Navigator.push(context, MaterialPageRoute(builder: (context) =>
                          ReminderScreen(isUpdate: false))
                      );
                      setState(() {});
                    }
                ),
                Bubble(
                    title: "Create Link",
                    titleStyle: const TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                    bubbleColor: Colors.grey.shade800,
                    icon: CupertinoIcons.link,
                    onPress: () {
                      _txtTitle.clear();
                      _txtLink.clear();
                      _createUrl(screenSize, coreNotifier, coreNotifier.currentPathAndroid);
                    }
                ),
              ],
            ),
          ),
          //Loader - CircularProgressIndicator When File Choosing
          isUploadingFile == true ? Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black.withOpacity(0.7),
              alignment: Alignment.center,
              // child: CircularProgressIndicator(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25, top: 30, bottom: 30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        color: Colors.grey.shade900,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          SizedBox(
                              // width: screenSize.width * 0.8,
                              child: Text(
                                "Please wait",
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              )
                          ),
                        ],
                      )
                  ),
                ],
              ),
            ),
          ) : const SizedBox.shrink(),
          //Signin Loader
          signInNotifier.isSigningIn == true ? Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black.withOpacity(0.7),
              alignment: Alignment.center,
              child: CircularProgressIndicator(),),
          ) : const SizedBox.shrink(),
        ],
      ),
    );
  }

  TextEditingController _txtTitle = TextEditingController();
  TextEditingController _txtLink = TextEditingController();

  _createUrl(Size screenSize, CoreNotifier coreNotifier, Directory currentDir) {
    showDialog(
        barrierDismissible: false,
        barrierColor: Colors.black54,
        context: _scaffoldKey.currentContext!,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text('Create Url'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: screenSize.width * 0.75,
                  child: TextField(
                    controller: _txtTitle,
                    decoration: InputDecoration(
                        hintText: 'Enter title here',
                        labelText: 'Title',
                        contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 8, right: 8),
                        border: OutlineInputBorder()
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: screenSize.width * 0.75,
                  child: TextField(
                    controller: _txtLink,
                    decoration: InputDecoration(
                        hintText: 'Paste link here',
                        labelText: 'Link',
                        contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 8, right: 8),
                        border: OutlineInputBorder()
                    ),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    isBlur = false;
                    _animationController.reverse();
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text("CANCEL")
              ),
              TextButton(
                  onPressed: () {


                    var tempLink = _txtLink.text.replaceAll('/', '£');
                    var tempLink1 = tempLink.replaceAll('?', ';');
                    var tempLink2 = tempLink1.replaceAll('&', '˜');
                    var tempLink3 = tempLink2.replaceAll('%', '(');
                    var finalLink = tempLink3.replaceAll(':', ',');
                    var joinFileName = finalLink + '^' + '${_txtTitle.text}.URL';
                    print('join @ ${_txtLink.text}');

                    coreNotifier.createEmptyFile(fileName: joinFileName, fileUrl: _txtLink.text, currentDir: currentDir, context: context)
                        .whenComplete((){
                          setState(() {
                            isBlur = false;
                            _animationController.reverse();
                          });
                        });

                    Navigator.pop(ctx);
                  },
                  child: const Text("CREATE")
              ),
            ],
          );
        }
    );

  }


  @override
  bool get wantKeepAlive => true;
}

