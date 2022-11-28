import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager_app/LocalDatabase/database.dart';
import 'package:filemanager_app/Screens/home_screen/home_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_storage_example/persisted_uri_card.dart';

class CoreNotifier extends ChangeNotifier {

  CoreNotifier(){
    initialize();
  }


  Directory currentPathAndroid = Directory("/storage/emulated/0/Akshar Notes/media");
  String mainFolderName = "Akshar Notes";
  late bool permissionGranted;
  late SharedPreferences prefs;
  DB db = DB();



  //this will create fillPath textfile in database folder and write data into it
  Future filePathsStoreLocally() async {
    List<String> lstPaths = [];

    Directory dirMedia = Directory("/storage/emulated/0/Akshar Notes/media");
    //directory and sub-directories listing to store paths in file
    dirMedia.list(recursive: true).forEach((element) {
      lstPaths.add(element.path);
    }).whenComplete(() async {

      final databasePath = "/storage/emulated/0/${mainFolderName}/database";
      if(!await Directory(databasePath).exists()) {
        await Directory(databasePath).create();
      }

      File pathFile = File("$databasePath/filePaths.txt");
      await pathFile.writeAsString(lstPaths.toString());

    });

  }


  //PERMISSIONS
  Future checkAndroidStoragePermission() async {
    var devideInfo = await DeviceInfoPlugin().androidInfo;
    var version = devideInfo.version.release;
    Future<PermissionStatus> status;

    if(int.parse(version!) > 10) {
      status = Permission.manageExternalStorage.request();
    } else {
      status = Permission.storage.request();
    }

    if(await status.isGranted) {
      permissionGranted = true;
    } else if(await status.isDenied || await status.isPermanentlyDenied) {
      permissionGranted = false;
    }
  }

  Future<void> initialize() async {
    var devideInfo = await DeviceInfoPlugin().androidInfo;
    var version = devideInfo.version.release;
    Future<PermissionStatus> status;

    if(version == "11") {
      status = Permission.manageExternalStorage.request();
    } else {
      status = Permission.storage.request();
    }

    currentPathAndroid = Directory("/storage/emulated/0");
    // currentPathAndroid = (await getExternalStorageDirectory())!;
    permissionGranted = false;
    print("_currentPathAndroid 1 -> $currentPathAndroid");

    if(Platform.isAndroid) {
      if(await status.isGranted) {
        if(!await Directory(currentPathAndroid.path + "/" + mainFolderName).exists()){
          await Directory(currentPathAndroid.path + "/" + mainFolderName).create();
        }
        if(!await Directory(currentPathAndroid.path + "/" + mainFolderName + "/media").exists()){
          await Directory(currentPathAndroid.path + "/" + mainFolderName + "/media").create();
        }
        if(!await Directory(currentPathAndroid.path + "/" + mainFolderName + "/database").exists()){
          await Directory(currentPathAndroid.path + "/" + mainFolderName + "/database").create().whenComplete(() async {
            await db.initNotificationFileDB();
          });
        }

      }
      currentPathAndroid = Directory(currentPathAndroid.path + "/" + mainFolderName + "/media");

      print("_currentPathAndroid 2 -> $currentPathAndroid");
      notifyListeners();
    }

  }

  Future<void> navigateToDirectory(String newPath) async {
    currentPathAndroid = Directory(newPath);
    notifyListeners();
  }

  Future<void> navigateBackFolder() async {
    if(currentPathAndroid.absolute.path == path.separator){

    } else {
      currentPathAndroid = currentPathAndroid.parent;
    }
    notifyListeners();
  }


  void reload() {
    notifyListeners();
  }


  Future<void> createFolder(String folderName, Directory currentDir, BuildContext context) async {

    if (!await Directory(currentDir.path + "/" + folderName).exists()) {
      await Directory(currentDir.path + "/" + folderName).create()
          .whenComplete(() async {

        var dir = Directory(currentDir.path + "/" + folderName);
        print("folder Created @" + dir.path);
        filePathsStoreLocally();

      });

    } else {
      Flushbar(
        icon: const Icon(Icons.info_outline, color: Colors.orange),
        message: "Folder name already exist",
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(context);

      print("folder name already existed");
    }
  }

  Future<void> createEmptyFile(
      {required String fileName,
      required String fileUrl,
      required Directory currentDir,
      required BuildContext context}) async {

    if(!await File(currentDir.path + '/' + '$fileName').exists()) {
      await File(currentDir.path + '/' + '$fileName').create().whenComplete(() async {

         var dir = File(currentDir.path + '/' + '$fileName');
         print("file Created @" + dir.path);
         filePathsStoreLocally();

      });

    } else {
      Flushbar(
        icon: const Icon(Icons.info_outline, color: Colors.orange),
        message: "File name already exist",
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(context);

      print("file name already existed");
    }
  }


  Future<void> writeURLFile(
      {required String fileName,
      required String fileUrl,
      required Directory currentDir,
      required BuildContext context}) async {

    final urlFile = File(currentDir.path + '/' + '$fileName');

    if(!await urlFile.exists()) {
      await urlFile.create().whenComplete(() async {

         var dir = urlFile;
         dir.writeAsStringSync(fileUrl);
         print("file Created @" + dir.path);
         filePathsStoreLocally();

      });

    } else {
      List<String> lstURLs = urlFile.readAsLinesSync();
      lstURLs.add(fileUrl);
      urlFile.writeAsStringSync(lstURLs.toString().replaceAll('[', '').replaceAll(']', ''));
      print("file name already existed -> $lstURLs");
    }
  }


  //CORE FILE FOLDERS
  Stream<List<FileSystemEntity>> fileStream(String path,
      {changeCurrentPath = true,
        Sorting sortedBy = Sorting.Type,
        reverse = false,
        recursive = false,
        keepHidden = false}) async* {
    Directory _path = Directory(path);
    List<FileSystemEntity> _files = <FileSystemEntity>[];
    try {
      if (_path.listSync(recursive: recursive).isNotEmpty) {
        if (!keepHidden) {
          yield* _path.list(recursive: recursive).transform(
              StreamTransformer.fromHandlers(
                  handleData: (FileSystemEntity data, sink) {
                    // debugPrint("filsytem_utils -> fileStream: $data");
                    // List<String>? readUrlFile;
                    // if(data.path.split('/').last == 'URLS.txt') {
                    //   final urlFile = File(data.path);
                    //   readUrlFile = urlFile.readAsLinesSync();
                    //   print('readUrlFile -> ${readUrlFile.first}');
                    // }
                    // final link = FileSystemEntity.isLinkSync(readUrlFile!.first.split(',')[2]);
                    // print('readUrlFile!.first -> ${readUrlFile.first.split(',')[2]}');
                    // print('is this link ? -> $link');
                    _files.add(data);
                    sink.add(_files);
                  }));
        } else {
          yield* _path.list(recursive: recursive).transform(
              StreamTransformer.fromHandlers(
                  handleData: (FileSystemEntity data, sink) {
                    // debugPrint("filsytem_utils -> fileStream: $data");
                    if (data.path.split("/").last.startsWith('.')) {
                      _files.add(data);
                      sink.add(_files);
                    }
                  }
              )
          );
        }
      } else {
        yield [];
      }
    } on FileSystemException catch (e) {
      print(e);
      yield [];
    }
  }

  Stream<List<FileSystemEntity>> searchStream(dynamic path, String query,
      {bool matchCase = false, recursive = true, bool hidden = false}) async* {
    yield* fileStream(path, recursive: recursive).transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      // Filtering
      data.retainWhere(
              (test) => test.path.split("/").last.toLowerCase().contains(query.toLowerCase()));
      sink.add(data);
    }));
  }



  Future<void> delete(String path) async {
    try {
      if (FileSystemEntity.isFileSync(path)) {
        print("Deleting file @ $path");
        await File(path).delete();
      } else if (FileSystemEntity.isDirectorySync(path)) {
        print("Deleting folder @ $path");
        await Directory(path).delete(recursive: true);
      } else if (FileSystemEntity.isFileSync(path)) {
        print("CoreNotifier->delete: $path");
        await Link(path).delete(recursive: true);
      }
    } catch (e) {
      print(e);
    }
    notifyListeners();
  }

  Future<void> rename(String _path, String newPath, BuildContext context1) async {
    try {
      if (FileSystemEntity.isFileSync(_path)) {
        print("Renaming file @ $newPath");
          await File(_path).rename(newPath);
      } else if (FileSystemEntity.isDirectorySync(_path)) {
        print("Renaming folder @ $newPath");
        await Directory(_path).rename(newPath);
      } else if (FileSystemEntity.isFileSync(_path)) {
        print("CoreNotifier->rename: $newPath");
        await Link(_path).rename(newPath);
      }
    } catch (e) {
      Flushbar(
        icon: const Icon(Icons.info_outline, color: Colors.orange),
        message: "Name already exist",
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(context1);

      print('rename error -> $e');
    }
    notifyListeners();
  }

}