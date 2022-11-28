import 'dart:collection';
import 'dart:io';
import 'package:filemanager_app/Global/global.dart';
import 'package:filemanager_app/Screens/home_screen/web_screen.dart';
import 'package:filemanager_app/Screens/home_screen/widgets/detail_pop_menu.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/utils/directory_utils.dart';
import 'package:filemanager_app/utils/googledrive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class FoldersListView extends StatefulWidget {
  final List<FileSystemEntity> folders;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<String> driveFileName;
  final BuildContext mainContext;
  List<NotificationFile> lstNotificationFile1;


  FoldersListView({
    Key? key,
    required this.folders,
    required this.scaffoldKey,
    required this.driveFileName,
    required this.mainContext,
    required this.lstNotificationFile1,
  }) : super(key: key);

  @override
  _FoldersListViewState createState() => _FoldersListViewState();
}

class _FoldersListViewState extends State<FoldersListView> {

  final TextEditingController _txtRenameList = TextEditingController();
  final GlobalKey<FormState> _formRenameKeyList = GlobalKey<FormState>();

  final drive = GoogleDrive();
  final DB db = DB();
  final Directory_Utils directory_utils = Directory_Utils();
  bool isFileSynced = false;
  late final List<FileSystemEntity> folders;

  List<NotificationFile> lstNotificationFile = [];
  ///Shows time in list tile
  Map<String, String> mapReminders = HashMap();
  Future getAllNotificationFile() async {
    lstNotificationFile = await db.getAllNotificationFileData();
    if(mounted) {
      setState(() {});
    }
  }


  ValueNotifier index1 = ValueNotifier(10000000000);

  @override
  void initState() {
    super.initState();
    folders = widget.folders;
    getAllNotificationFile();
    mapReminders.clear();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    var coreNotifier = Provider.of<CoreNotifier>(context);

    return ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 15),
        itemCount: folders.length,
        itemBuilder: (BuildContext context, int index){
          FileSystemEntity folder = folders[index];
          Map<String, int> dir = directory_utils.dirSize(folder.path);

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
                print("element.fileName -> ${element.fileName}  matches -> ${folder.path.split('/').last}");
                return element.fileName == folder.path.split('/').last;
              }
            });

            print("lstNotificationFile.length -> ${lstNotificationFile.length}");
            if(index1.value >= 0) {
              print("index1.value -> ${index1.value}");
              print("lstNotificationFile[index1.value].fileName! -> ${lstNotificationFile[index1.value].fileName!}");
              mapReminders[lstNotificationFile[index1.value].fileName!] = lstNotificationFile[index1.value].dateTime;
            }

          });


          return InkWell(
            onTap: () async {

              if(FileSystemEntity.isDirectorySync(folder.path)) {

                coreNotifier.navigateToDirectory(folder.path);

              } else {

                if(path.extension(folder.path) == '.URL') {
                  var tempLink = folder.path.split('/').last.split('^').first.replaceAll('£', '/');
                  var finalLink1 = tempLink.replaceAll(';', '?');
                  var finalLink2 = finalLink1.replaceAll('˜', '&');
                  var finalLink3 = finalLink2.replaceAll('(', '%');
                  var finalLink4 = finalLink3.replaceAll(',', ':');
                  print('finalLink.contains(https://) -> ${finalLink4.contains('https://')}');
                  if(finalLink4.contains('https://') || finalLink4.contains('http://')) {
                  print('path.extension(folder.path) 11-> $finalLink4');
                  //   await launch('$finalLink4', forceWebView: true, enableJavaScript: false);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WebScreen(url: finalLink4)));
                  } else {
                  print('path.extension(folder.path) 22-> $finalLink4');
                  //   await launch('https://$finalLink4', forceWebView: true, enableJavaScript: true);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WebScreen(url: finalLink4)));
                  }
                } else {
                  OpenFile.open(folder.path);
                }

              }
            },
            child: Container(
              height: 76,
              width: screenSize.width * 0.8,
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          //Image
                          Stack(
                            children: [
                              Container(
                                height: screenSize.width * 0.12,
                                width: screenSize.width * 0.12,
                                child: directory_utils.fileTypeImageGrid(folder.path, index),
                              ),
                              driveFileName.contains(folder.path.split("/").last) ? Positioned(
                                  bottom: -2,
                                  right: -1,
                                  child: CircleAvatar(
                                    radius: 10.5,
                                    backgroundColor: Colors.black,
                                    child: CircleAvatar(
                                      child: Icon(Icons.cloud_done, color: Colors.green, size: 13),
                                      backgroundColor: Colors.white,
                                      radius: 9,
                                    ),
                                  )
                              ) : SizedBox.shrink(),
                            ],
                          ),
                          const SizedBox(width: 10),
                          //Text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(bottom: 8),
                                width: screenSize.width * 0.3,
                                child: Text(
                                  //if extension .URL == webfile
                                  path.extension(folder.path) == '.URL'
                                      ? filename.split('.').first
                                      : folder.path.split("/").last,
                                  style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              path.extension(folder.path) == '.URL'?
                              Container(
                                width: screenSize.width * 0.3,
                                child: Text(
                                  fileurl,
                                  style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w400, color: Colors.blue, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                                  : directory_utils.fileFolderSize(folder.path, dir, const TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 13))
                            ],
                          ),
                          Spacer(),

                          //Shows time in list tile
                          lstNotificationFile.length > 0 ? ValueListenableBuilder(
                              valueListenable: index1,
                              builder: (BuildContext context, value, Widget? child) {

                                return mapReminders.containsKey(folder.path.split('/').last) || mapReminders.containsKey(folder.path.split('/').last.split('^').last) ? Container(
                                    alignment: Alignment.topRight,
                                    height: 35,
                                    width: screenSize.width * 0.44,
                                    child: path.extension(folder.path) != '.URL'
                                        ? !mapReminders[folder.path.split('/').last]!.contains('Every') ?
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        Text(mapReminders[folder.path.split('/').last]!.split('|').first),
                                        Text('| ' + mapReminders[folder.path.split('/').last]!.split('|').last, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300),textAlign: TextAlign.end),
                                      ],
                                    ) :
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        Text('M  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Monday') ? Colors.blueAccent : Colors.white)),
                                        Text('T  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Tuesday') ? Colors.blueAccent : Colors.white)),
                                        Text('W  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Wednesday') ? Colors.blueAccent : Colors.white)),
                                        Text('T  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Thursday') ? Colors.blueAccent : Colors.white)),
                                        Text('F  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Friday') ? Colors.blueAccent : Colors.white)),
                                        Text('S  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Saturday') ? Colors.blueAccent : Colors.white)),
                                        Text('S ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last]!.contains('Every Sunday') ? Colors.blueAccent : Colors.white)),
                                        Text('| ' + mapReminders[folder.path.split('/').last]!.split('|').last, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300),textAlign: TextAlign.end),
                                      ],
                                    )
                                    //If it is not .URL file
                                        : !mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every') ?
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(mapReminders[folder.path.split('/').last.split('^').last]!.split('|').first),
                                        Text('| ' + mapReminders[folder.path.split('/').last.split('^').last]!.split('|').last, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300),textAlign: TextAlign.end),
                                      ],
                                    ) :
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('M  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Monday') ? Colors.blueAccent : Colors.white)),
                                        Text('T  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Tuesday') ? Colors.blueAccent : Colors.white)),
                                        Text('W  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Wednesday') ? Colors.blueAccent : Colors.white)),
                                        Text('T  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Thursday') ? Colors.blueAccent : Colors.white)),
                                        Text('F  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Friday') ? Colors.blueAccent : Colors.white)),
                                        Text('S  ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Saturday') ? Colors.blueAccent : Colors.white)),
                                        Text('S ', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: mapReminders[folder.path.split('/').last.split('^').last]!.contains('Every Sunday') ? Colors.blueAccent : Colors.white)),
                                        Text('| ' + mapReminders[folder.path.split('/').last.split('^').last]!.split('|').last, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300),textAlign: TextAlign.end),
                                      ],
                                    )
                                ) : SizedBox.shrink();
                              }

                          ) : SizedBox.shrink(),

                          SizedBox(width: 10),

                          //Popup button
                          Container(
                              height: 30,
                              width: 30,
                              child: ValueListenableBuilder(
                                valueListenable: index1,
                                builder: (BuildContext context, value, Widget? child) {
                                  return Detail_Popup(
                                    scaffoldKey: widget.scaffoldKey,
                                    dir: dir,
                                    folder: folder,
                                    folders: folders,
                                    formRenameKey: _formRenameKeyList,
                                    txtRename: _txtRenameList,
                                    isFileSynced: isFileSynced,
                                    screenSize: screenSize,
                                    driveFileName: driveFileName,
                                    index: index,
                                    filename: filename,
                                    fileurl: fileurl,
                                    mainContext: widget.mainContext,
                                    isEdit: mapReminders.containsKey(folder.path.split('/').last) || mapReminders.containsKey(folder.path.split('/').last.split('^').last) ?
                                    true : false,
                                    // notificationFileName: mapReminders.containsKey(folder.path.split('/').last) || mapReminders.containsKey(folder.path.split('/').last.split('^').last) ?
                                    //   index1.value >= 0 ? lstNotificationFile[index1.value].fileName : null : null,
                                    lstnotificationFile: lstNotificationFile,
                                  );
                                },
                              )
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Flexible(
                          child: Divider(
                            indent: screenSize.width * 0.168,
                            thickness: 1,
                          )
                      )
                    ],
                  )
              ),
            ),
          );
        }
    );
  }
}

