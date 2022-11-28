// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:collection';
import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager_app/Screens/home_screen/widgets/detail_pop_menu.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:filemanager_app/Screens/home_screen/home_screen.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/notifiers/google_sign_in_provider.dart';
import 'package:filemanager_app/utils/directory_utils.dart';
import 'package:filemanager_app/utils/googledrive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';


// ignore: must_be_immutable
class FoldersWidget extends StatelessWidget {
  final List<FileSystemEntity> folders;
  final Size screenSize;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List driveFileName;
  final BuildContext mainContext;
  List<NotificationFile> lstNotificationFile;

  FoldersWidget({
    required this.folders,
    required this.screenSize,
    required this.scaffoldKey,
    required this.driveFileName,
    required this.mainContext,
    required this.lstNotificationFile
  });

  final TextEditingController _txtRenameGird = TextEditingController();
  final GlobalKey<FormState> _formRenameKeyGrid = GlobalKey<FormState>();

  final drive = GoogleDrive();
  DB db = DB();
  final Directory_Utils directory_utils = Directory_Utils();

  bool isFileSynced = false;

  Map<String, String> mapReminders = HashMap();
  Future getAllNotificationFile() async {
    lstNotificationFile = await db.getAllNotificationFileData();
  }

  ValueNotifier index1 = ValueNotifier(10000000000);

  @override
  Widget build(BuildContext ctx) {
    getAllNotificationFile();
    mapReminders.clear();

    var coreNotifier = Provider.of<CoreNotifier>(ctx);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(childAspectRatio: 0.75, crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 10),
      padding: const EdgeInsets.only(top: 25, bottom: 40, right: 10, left: 10),
      itemCount: folders.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var folder = folders[index];

        var dir = directory_utils.dirSize(folder.path);
        driveFileName.forEach((element) {
          if(element == folder.path.split('/').last) {
            print("driveFileName @ $element");
          }
        });

        String filename;
        String fileurl;
        //for webfile
        if(path.extension(folder.path) == '.URL'){
          filename = folder.path.split('/').last.split('^').last;
          var tempLink = folder.path.split('/').last.split('^').first.replaceAll('£', '/');
          fileurl = tempLink.replaceAll('=', ':');
        } else {
          filename = '';
          fileurl = '';
        }

        //Shows time in list tile
        Future.delayed(const Duration(milliseconds: 100), () {
          index1.value = lstNotificationFile.indexWhere((element) {
            if(path.extension(folder.path) == '.URL') {
              return element.fileName == folder.path.split('/').last.split('^').last;
            } else {
              return element.fileName == folder.path.split('/').last;
            }
          });

          if(index1.value >= 0) {
            mapReminders[lstNotificationFile[index1.value].fileName!] = lstNotificationFile[index1.value].dateTime;
          }

        });

        return Column(
          children: [
            InkWell(
              onTap: () async {
                if(FileSystemEntity.isDirectorySync(folder.path)){

                  coreNotifier.navigateToDirectory(folder.path);

                } else {

                  if(path.extension(folder.path) == '.URL') {
                    var tempLink = folder.path.split('/').last.split('^').first.replaceAll('£', '/');
                    var finalLink = tempLink.replaceAll('=', ':');
                    await launch('https://$finalLink', forceWebView: true, enableJavaScript: true);
                  } else {
                    OpenFile.open(folder.path);
                  }

                }

              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //FOLDER - FILE IMAGE
                  Stack(
                    children: [
                      Container(
                        height: screenSize.width * 0.19,
                        width: screenSize.width * 0.2,
                        child: Hero(
                          tag: 'hero',
                          child: directory_utils.fileTypeImageGrid(folder.path, index),
                        ),
                      ),
                      driveFileName.contains(folder.path.split('/').last) ? Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black,
                            child: CircleAvatar(
                              child: Icon(Icons.cloud_done, color: Colors.green, size: 17),
                              backgroundColor: Colors.white,
                              radius: 13,
                            ),
                          )
                      ) : SizedBox.shrink()
                    ],
                  ),
                  const SizedBox(height: 7),
                  //FOLDER - FILE NAME
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      width: screenSize.width * 0.8,
                      child: Text(
                        path.extension(folder.path) == '.URL'
                            ? filename.split('.').first
                            : folder.path.split("/").last,
                        style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      )
                  ),
                  const SizedBox(height: 6),
                  path.extension(folder.path) == '.URL'?
                  Text(
                    //if extension .URL == webfile
                    fileurl,
                    style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w400, color: Colors.blue, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  )
                  //FOLDER - FILE SIZE AND ITEMS
                      : directory_utils.fileFolderSize(folder.path, dir, const TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 9),),
                  Container(
                    height: 28,
                    width: 24,
                    child: ValueListenableBuilder(
                      valueListenable: index1,
                      builder: (BuildContext context, value, Widget? child) {
                        return Detail_Popup(
                          scaffoldKey: scaffoldKey,
                          dir: dir,
                          folder: folder,
                          folders: folders,
                          formRenameKey: _formRenameKeyGrid,
                          txtRename: _txtRenameGird,
                          isFileSynced: isFileSynced,
                          screenSize: screenSize,
                          driveFileName: driveFileName,
                          index: index,
                          filename: filename,
                          fileurl: fileurl,
                          mainContext: mainContext,
                          isEdit: mapReminders.containsKey(folder.path.split('/').last) || mapReminders.containsKey(folder.path.split('/').last.split('^').last) ?
                          true : false,
                          // notificationFileName: mapReminders.containsKey(folder.path.split('/').last) || mapReminders.containsKey(folder.path.split('/').last.split('^').last) ?
                          //   index1.value >= 0 ? lstNotificationFile[index1.value].fileName : null : null,
                          lstnotificationFile: lstNotificationFile,
                        );
                      },
                    )
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}