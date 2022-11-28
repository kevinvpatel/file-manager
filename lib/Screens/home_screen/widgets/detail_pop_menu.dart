// ignore_for_file: import_of_legacy_library_into_null_safe
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:filemanager_app/Global/global_widgets.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:filemanager_app/Screens/reminder_screen.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/notifiers/google_sign_in_provider.dart';
import 'package:filemanager_app/utils/directory_utils.dart';
import 'package:filemanager_app/utils/googledrive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

// ignore: must_be_immutable
class Detail_Popup extends StatelessWidget {

  final TextEditingController txtRename;
  final GlobalKey<FormState> formRenameKey;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final BuildContext mainContext;

  final FileSystemEntity folder;
  final List<FileSystemEntity> folders;

  final Map<String, int> dir;
  bool isFileSynced;
  final Size screenSize;
  final List driveFileName;
  final int index;
  final String? filename;
  final String? fileurl;
  List<NotificationFile> lstnotificationFile;
  bool? isEdit;

  Detail_Popup({
    required this.txtRename,
    required this.formRenameKey,
    required this.folder,
    required this.scaffoldKey,
    required this.folders,
    required this.dir,
    required this.isFileSynced,
    required this.screenSize,
    required this.driveFileName,
    required this.index,
    this.filename, this.fileurl,
    required this.mainContext,
    required this.lstnotificationFile,
    this.isEdit,
  });

  final db = DB();
  final drive = GoogleDrive();
  final directory_utils = Directory_Utils();

  final TextEditingController txtRenameLink = TextEditingController();

  ///this will edit from list or grid notification
  getNotificationData({required String currentPath, required BuildContext context}) async {
    if(lstnotificationFile != null) {
      lstnotificationFile.forEach((element) async {
        if(element.fileName != null) {
          if(currentPath.split('/').last == element.fileName || currentPath.split('/').last.split('^').last == element.fileName) {
            await db.getNotificationFileNameData(element.fileName!).then((value) {
              value.forEach((element) {
                print('lst -> ${element.fileName}');
                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    ReminderScreen(
                      fileId: element.fileId,
                      fileName: element.fileName,
                      title: element.title,
                      description: element.description,
                      dateTime: element.dateTime,
                      uid: element.notificationId,
                      isUpdate: true,
                      isFile: element.isFile,
                      filePath: element.filePath,
                    )
                ));
              });
            });
          }
        }
      });
    }
  }

  ///this will update file name and path in notification database when user rename file / folder
  updateNotificationFile({required String currentPath, required String newPath}) {
    if(lstnotificationFile != null) {
      lstnotificationFile.forEach((element) async {
        if(element.fileName != null) {
          if(currentPath.split('/').last == element.fileName || currentPath.split('/').last.split('^').last == element.fileName) {
            await db.getNotificationFileNameData(element.fileName!).then((value) {

              value.forEach((element) {
                print('lst -> ${element.fileName}');
                db.updateNotificationFileData(NotificationFile(
                    fileName: path.extension(newPath) == '.URL' ? newPath.split('/').last.split('^').last : newPath.split('/').last,
                    title: element.title,
                    dateTime: element.dateTime,
                    isComplete: element.isComplete,
                    description: element.description,
                    fileId: element.fileId,
                    notificationId: element.notificationId,
                    isFile: element.isFile,
                    filePath: newPath
                ));
              });

            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    var coreNotifier = Provider.of<CoreNotifier>(ctx);
    var signInNotifier = Provider.of<GoogleSignInProvider>(ctx);

    return PopupMenuButton(
        padding: const EdgeInsets.only(bottom: 0),
        icon: const Icon(CupertinoIcons.ellipsis, size: 18, color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        itemBuilder: (BuildContext context) => [
          //RENAME
          PopupMenuItem(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Rename"),
                  Icon(CupertinoIcons.pen, size: 20, color: Colors.white),
                ],
              ),
              value: 2,
              onTap: () async {
                print("tapped rename");

                //Store name for rename in textfield
                if(path.extension(folder.path) == '.URL') {
                  var titleWithoutExtension = filename!.substring(0, filename!.indexOf('.URL'));
                  txtRename.text = titleWithoutExtension;
                  txtRename.selection = TextSelection(baseOffset: 0, extentOffset: titleWithoutExtension.length);
                  txtRenameLink.text = fileurl!;
                } else {
                  String folderFileName = folder.path.split("/").last;
                  txtRename.text = folderFileName;
                  if(FileSystemEntity.isDirectorySync(folder.path)) {
                    txtRename.selection = TextSelection(baseOffset: 0, extentOffset: folderFileName.length);
                  } else {
                    int idxOfExtension = folder.path.split("/").last.indexOf('.');
                    txtRename.selection = TextSelection(baseOffset: 0, extentOffset: idxOfExtension);
                  }
                }

                SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
                  dialogeMessageBox(
                      scaffoldKey.currentContext!,
                      title: const Text("Rename!"),
                      edgeInsets: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                      children: [
                        path.extension(folder.path) == '.URL'
                            ? Form(
                            key: formRenameKey,
                            child: SizedBox(
                              width: screenSize.width * 0.75,
                              child: Column(
                                children: [
                                  TextFormField(
                                    autofocus: true,
                                    controller: txtRename,
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                        labelText: "URL Title",
                                        contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 7, right: 7),
                                        border: const OutlineInputBorder()
                                    ),
                                    validator: (newName){
                                      //COMPARING FOLDER NAME FOR CHECKING EXISTING.
                                      // var contain = folders.where((element) =>
                                      //   element.path.split("/").last.split("^").last == '$newName.URL'
                                      // );
                                      //
                                      // var fileName;
                                      // contain.forEach((element) {
                                      //   if(element.path.split('/').last.split('^').last.split('.').first == newName) {
                                      //     fileName = element.path.split('/').last;
                                      //     print('Webfile Name -> $fileName');
                                      //   }
                                      // });

                                      if(newName!.isEmpty){
                                        return "URL name can't be empty";
                                      } else {
                                        return null;
                                      }
                                    },
                                    textCapitalization: TextCapitalization.sentences,
                                  ),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: txtRenameLink,
                                    maxLines: 1,
                                    decoration: InputDecoration(
                                        labelText: "URL",
                                        contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 7, right: 7),
                                        border: const OutlineInputBorder()
                                    ),
                                    validator: (newName){
                                      //COMPARING FOLDER NAME FOR CHECKING EXISTING.
                                      // var contain = folders.where((element) => element.path.split("/").last.split("^").first == newName);
                                      if(newName!.isEmpty){
                                        return "URL can't be empty";
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                ]
                              ),
                            )
                        )
                        : Form(
                          key: formRenameKey,
                          child: SizedBox(
                            width: screenSize.width * 0.75,
                            child: TextFormField(
                              autofocus: true,
                              controller: txtRename,
                              maxLines: 1,
                              decoration: InputDecoration(
                                  labelText: FileSystemEntity.isDirectorySync(folder.path) ? "Folder" : "File",
                                  contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 7, right: 7),
                                  border: const OutlineInputBorder()
                              ),
                              validator: (newName){
                                //COMPARING FOLDER NAME FOR CHECKING EXISTING.
                                // var contain = folders.where((element) {
                                //   if(FileSystemEntity.isDirectorySync(element.path)) {
                                //     return element.path.split("/").last == newName;
                                //   } else {
                                //     return element.path.split("/").last.split('.').first == newName;
                                //   }
                                // });
                                // print('contain -> $contain');
                                // print('newName -> $newName');
                                //
                                // var fileName;
                                // contain.forEach((element) {
                                //   if(FileSystemEntity.isDirectorySync(element.path)) {
                                //     if(element.path.split('/').last == newName) {
                                //       fileName = element.path.split('/').last;
                                //       print('folderName -> $fileName');
                                //     }
                                //   } else {
                                //     if(element.path.split('/').last.split('.').first == newName) {
                                //       fileName = element.path.split('/').last;
                                //       print('fileName -> $fileName');
                                //     }
                                //   }
                                // });

                                if(newName!.isEmpty){
                                  return "Please enter folder name";
                                } else {
                                  return null;
                                }
                              },
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          )
                        )
                      ],
                      buttons: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(scaffoldKey.currentContext!);
                            },
                            child: const Text("CANCEL")
                        ),
                        TextButton(
                            onPressed: (){
                              if(formRenameKey.currentState!.validate()){

                                SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {

                                  String removableName = folder.path.split("/").last;
                                  int idx = folder.path.indexOf(removableName);
                                  String tmpPath = folder.path.substring(0, idx);
                                  String finalPath = '';
                                  if(path.extension(folder.path) == '.URL') {
                                    var tempLink = txtRenameLink.text.replaceAll('/', '£');
                                    var finalLink = tempLink.replaceAll(':', '=');
                                    finalPath = tmpPath + finalLink + "^" + '${txtRename.text}.URL';
                                  } else {
                                    finalPath = tmpPath + txtRename.text;
                                  }

                                  coreNotifier.rename(folder.path, finalPath, mainContext).whenComplete(() {
                                    updateNotificationFile(newPath: finalPath, currentPath: folder.path);
                                  });
                                  coreNotifier.reload();
                                  Navigator.pop(scaffoldKey.currentContext!);
                                  Future.delayed(const Duration(milliseconds: 700), () {
                                    txtRename.clear();
                                    txtRenameLink.clear();
                                  });

                                });

                              } else {
                                print("Rename Field cant be empty");
                              }
                            },
                            child: const Text("OK")
                        ),
                      ]
                  );
                });
              }
          ),
          //DELETE
          PopupMenuItem(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Delete"),
                  Icon(CupertinoIcons.delete_solid, size: 20, color: Colors.white),
                ],
              ),
              value: 1,
              onTap: () {
                SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
                  showDialog(
                      context: scaffoldKey.currentContext!,
                      barrierColor: Colors.black54,
                      barrierDismissible: false,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
                            title: const Text("Delete"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FileSystemEntity.isDirectorySync(folder.path)
                                    ? Text(
                                    "Do you want to delete the folder: ${folder
                                        .path
                                        .split("/")
                                        .last}?")
                                    : Text(
                                    "Do you want to delete File: ${path.extension(folder.path) == '.URL'
                                        ? filename
                                        : folder.path.split("/").last} ?"),

                                const SizedBox(height: 10),

                                path.extension(folder.path) == '.URL'
                                    ? SizedBox.shrink()
                                    : Row(
                                  children: [
                                    const Text("Size : "),
                                    directory_utils.fileFolderSize(
                                        folder.path, dir, const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        fontSize: 14))
                                  ],
                                ),
                              ],
                            ),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(
                                        scaffoldKey.currentContext!),
                                child: const Text("CANCEL")
                            ),
                            TextButton(
                                onPressed: () {
                                  SchedulerBinding.instance!
                                      .addPostFrameCallback((timeStamp) {
                                    Navigator.pop(
                                        scaffoldKey.currentContext!);
                                    coreNotifier.delete(folder.path)
                                        .whenComplete(() async {
                                      // await db.deleteNotificationFileData(folder.path.split('/').last);
                                      coreNotifier.reload();
                                      toast('${path.extension(folder.path) == '.URL'
                                          ? filename
                                          : folder.path.split('/').last}  Deleted successfully');

                                      ///this will delete notification too with its file
                                      lstnotificationFile.forEach((element) async {
                                        if(element.fileName == folder.path.split("/").last || element.fileName == filename) {
                                          print("deleted file name -> ${element.fileName}");
                                          await AwesomeNotifications().cancel(int.parse(element.notificationId));
                                          await db.deleteNotificationFileData(element.fileId!);
                                        }
                                      });

                                      print("deleted successfully");
                                    });
                                  });
                                },
                                child: const Text("OK")
                            )
                          ],
                        );
                      }
                  );
                });
              }
          ),
          //SET REMINDER
          PopupMenuItem(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit == true ? "Edit Reminder" : "Set Reminder"),
                Icon(CupertinoIcons.timer, size: 20, color: Colors.white),
              ],
            ),
            value: 2,
            onTap: () {
              SchedulerBinding.instance!.addPostFrameCallback((_) {
                if(isEdit == true) {
                  // print('isEdit 2-> ${notificationFile!.fileName}');
                  getNotificationData(currentPath: folder.path, context: context);
                  print('navigate to edit');
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      ReminderScreen(
                        fileName: path.extension(folder.path) == '.URL'
                            ? filename!
                            : folder.path.split("/").last,
                        isUpdate: false,
                        //Folder = 0, File = 1
                        isFile: FileSystemEntity.isDirectorySync(folder.path) ? 0 : 1,
                        filePath: folder.path,
                      ),
                  )).then((value) {
                    coreNotifier.reload();
                  });
                }
              });
            },
          ),
          //DETAILS
          PopupMenuItem(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Details"),
                Icon(CupertinoIcons.question_circle, size: 20, color: Colors.white)
              ],
            ),
            onTap: () async {
              int idx = folder.path.indexOf(folder.path.split("/").last);
              String finalPath = folder.path.substring(0, idx);
              // var tempTapped = await db.getNamedRecentFileData(folder.path.split("/").last);
              // for (var file in tempTapped) {
              //   isFileSynced = file.isSynced == 1 ? true : false;
              // }

              var date = FileStat.statSync(folder.path).modified;
              String formattedDate = DateFormat('dd-MM-yyyy, HH:mm a').format(date);
              print('modified date -> $formattedDate');


              TextStyle textStyle = TextStyle(color: Colors.white, fontSize: 14);
              SchedulerBinding.instance!.addPostFrameCallback((timeStamp) {
                dialogeMessageBox(
                    scaffoldKey.currentContext!,
                    edgeInsets: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    children: [
                      Column(
                        children: [
                          //DETAIL HEADER
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start ,
                              children: [
                                SizedBox(
                                  height: screenSize.width * 0.18,
                                  width: screenSize.width * 0.18,
                                  child: Hero(
                                    tag: 'hero',
                                    child: directory_utils.fileTypeImageGrid(folder.path, index),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                      width: screenSize.width * 0.50,
                                      child: Text(path.extension(folder.path) == '.URL'
                                          ? filename!.split('.').first
                                          : folder.path.split("/").last, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),)
                                  ),
                                )
                              ],
                            ),
                          ),
                          const Divider(color: Colors.grey,),
                          //TYPE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("Type : ", style: textStyle),
                                const SizedBox(width: 10),
                                Text(FileSystemEntity.isDirectorySync(folder.path) ? "Folder" : path.extension(folder.path) == '.URL'
                                    ? "URL"
                                    : "File", style: textStyle),
                              ],
                            ),
                          ),
                          //PATH
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(path.extension(folder.path) == '.URL' ? "Url : " : "Path : ", style: textStyle),
                                const SizedBox(width: 10),
                                Expanded(child:
                                  path.extension(folder.path) == '.URL'
                                      ? Text(fileurl!, style: TextStyle(color: Colors.blue, fontSize: 14, decoration: TextDecoration.underline),)
                                      : Text(finalPath, style: textStyle)
                                ),
                                InkWell(
                                  onTap: () async {
                                    if(path.extension(folder.path) == '.URL'){

                                      String link = folder.path.split('/').last.split('^').first;
                                      var tempLink = link.replaceAll('£', '/');
                                      var finalLink = tempLink.replaceAll('=', ':');
                                      await Clipboard.setData(ClipboardData(text: finalLink));
                                      toast('link copied : $finalLink');

                                    } else {

                                      await Clipboard.setData(ClipboardData(text: folder.path));
                                      toast('path copied : ${folder.path}');

                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(50)),
                                        color: Colors.white),
                                    height: 26,
                                    width: 26,
                                    alignment: Alignment.center,
                                    child: Icon(Icons.copy, size: 15, color: Colors.black87),
                                  ),
                                  splashColor: Colors.transparent,
                                )
                              ],
                            ),
                          ),
                          //SIZE
                          path.extension(folder.path) == '.URL'
                              ? SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text("Size : ", style: textStyle),
                                    const SizedBox(width: 10),
                                    directory_utils.fileFolderSize(folder.path, dir, textStyle)
                                  ],
                                ),
                          ),
                          //MODIFIED
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Modified :', style: textStyle),
                                SizedBox(width: 10),
                                Text(formattedDate, style: textStyle)
                              ],
                            ),
                          ),
                          const Divider(color: Colors.grey,),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                !FileSystemEntity.isDirectorySync(folder.path) ?
                                path.extension(folder.path) == '.URL' ? SizedBox.shrink() :
                                driveFileName.contains(folder.path.split('/').last)
                                    ? const Text("Syncronized", style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),)
                                : InkWell(
                                  onTap: () async {
                                    var _user = FirebaseAuth.instance.currentUser;
                                    // var _signin = await signInNotifier.googleSignIn.signIn();

                                    Navigator.pop(scaffoldKey.currentContext!);

                                    if(_user == null){
                                      signInNotifier.login(scaffoldKey.currentContext!).whenComplete(() async {

                                        Future.delayed(const Duration(seconds: 2),(){
                                          drive.uploadFile(folder, context, coreNotifier);
                                        });

                                      });
                                    } else {
                                      drive.uploadFile(folder, context, coreNotifier);
                                    }

                                    // for (var file in tempTapped) {
                                    //   db.updateRecentFileData(RecentFile(
                                    //     recentFileId: file.recentFileId,
                                    //     recentFileCreatedDate: file.recentFileCreatedDate,
                                    //     isSynced: _user != null ? 1 : 0,
                                    //     recentFileSize: file.recentFileSize,
                                    //     recentFilePath: file.recentFilePath,
                                    //     recentFileName: file.recentFileName,
                                    //   ));
                                    //   print("tappedFile -> ${file.recentFileName}");
                                    // }

                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(right: 30, top: 2, bottom: 2),
                                    child: Text("Sync Now", style: TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w500)),
                                  ),
                                  splashColor: Colors.transparent,
                                ) : const SizedBox.shrink(),

                                InkWell(
                                    onTap: ()=> Navigator.pop(scaffoldKey.currentContext!),
                                    child: Container(
                                      padding: EdgeInsets.only(left: 30, top: 2, bottom: 2),
                                      child: Text("CANCEL", style: TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w500)),
                                    ),
                                    splashColor: Colors.transparent,
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ]
                );
              });
            },
          ),
        ]
    );
  }
}

