import 'dart:io';
import 'dart:developer' as logger;
import 'package:another_flushbar/flushbar.dart';
import 'package:filemanager_app/Global/global_widgets.dart';
import 'package:filemanager_app/Models/google_file.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:filemanager_app/notifiers/google_sign_in_provider.dart';
import 'package:filemanager_app/utils/googledrive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:shared_preferences/shared_preferences.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {

  final gDrive = GoogleDrive();
  double progress = 0;
  bool isUploading = false;
  bool isDownloading = false;
  late SharedPreferences prefs;


  List<String> arrFiles = [];
  int uploadedCounter = 0;
  String fileName = '';

  _flushbar({required String msg}){
    return Flushbar(
        showProgressIndicator: false,
        boxShadows: const [
          BoxShadow(
              color: Colors.black45,
              offset: Offset(3, 3),
              blurRadius: 3
          )
        ],
        icon: const Icon(Icons.cloud_done_outlined, color: Colors.green),
        message: msg,
        duration: const Duration(milliseconds: 1900),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8)
    );
  }

  _flushbarError({required String msg}) {
    return Flushbar(
        showProgressIndicator: false,
        boxShadows: const [
          BoxShadow(
              color: Colors.black45,
              offset: Offset(3, 3),
              blurRadius: 3
          )
        ],
        icon: const Icon(Icons.error_outline, color: Colors.red),
        message: msg,
        duration: const Duration(milliseconds: 1900),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8)
    );
  }


  double uploadProgress = 0;

  uploadDrive({required FileSystemEntity element, required gd.DriveApi drive}) async {
    prefs = await SharedPreferences.getInstance();

    gd.File fileToUpload = gd.File();
    final folderId = await gDrive.getFolderID(drive);

    var file = File(element.path);
    final contentLength = file.lengthSync();
    final bytes = <int>[];

    //------------> Store filePath.txt id in shared prefs and check with condition if prefs have fileid then put data in that fileid <------------

    String? fileId;

    if(element.path.split("/").last == "filePaths.txt") {
      fileId = await gDrive.getFileID(drive);
      print('fileId @ $fileId');
    }

    fileToUpload.name = element.path.split("/").last;
    fileToUpload.parents = [folderId!];

    fileName = element.path.split("/").last;

    //Progress Show
    file.openRead().listen((event) {
      bytes.insertAll(bytes.length, event);
      _setState(() {
        uploadProgress = bytes.length / file.lengthSync();
      });
    }).onDone(() {
      uploadProgress = 0.99;
      _setState(() {});
    });


    try{
      gd.File response;
      if(fileId != null) {
        print('filePaths.txt updating...');

        await drive.files.delete(fileId);

        print('filePaths.txt updating2...');
        response = await drive.files.create(
            fileToUpload,
            uploadMedia: gd.Media(file.openRead(), file.lengthSync())
        ).whenComplete(() {
          uploadedCounter += 1;
          print("uploadedCounter $uploadedCounter");
          print("arrFiles.length ${arrFiles.length}");
        });

      } else {

        response = await drive.files.create(
            fileToUpload,
            uploadMedia: gd.Media(file.openRead(), file.lengthSync())
        ).whenComplete(() {
          uploadedCounter += 1;
          print("uploadedCounter $uploadedCounter");
          print("arrFiles.length ${arrFiles.length}");
        });

      }


      if(uploadedCounter == arrFiles.length){
        print('Complete@@@@');

        Navigator.pop(_context);
        // isUploading = false;
        uploadProgress = 1;
        setState(() {});

        _flushbar(msg: "Backup Successfully").show(context);

      }

      toast("\"${response.name}\" uploaded");

      print("\"${response.id}\" iddddd");

      print("uploaded response name ${response.name}");
    } catch(e) {
      Navigator.pop(_context);
      _flushbarError(msg: "Please try again!! backup failed").show(context);
      print(e);
    }

  }

  //button to upload all files to google drive
  onPressBackup({required BuildContext context, required CoreNotifier coreNotifier}) async {

    backupDialogeBox(context);

    try {
      arrFiles.clear();
      isUploading = true;

      setState(() {});

      logger.log('pressed ... ');
      Directory dirMedia = Directory("/storage/emulated/0/Akshar Notes/media");
      Directory dirDatabase = Directory("/storage/emulated/0/Akshar Notes/database");

      gd.DriveApi drive = gd.DriveApi(await gDrive.clientAuth());

      await dirMedia.list(recursive: true).forEach((file) {
        if(FileSystemEntity.isFileSync(file.path)) {
          arrFiles.add(file.path);
          uploadDrive(element: file, drive: drive);
        }
      });

      await dirDatabase.list(recursive: true).forEach((file) {
        if(FileSystemEntity.isFileSync(file.path)) {
          arrFiles.add(file.path);
          uploadDrive(element: file, drive: drive);
        }
      });

    } catch(e) {
      print("backup error -> $e");
    }

  }


  //------------> Get filePath.txt file's id and update textfile on that id  <------------

  String file_name = "files";

  Future downloadGoogleDriveFiles({
    required List<gd.File> files,
    gd.Media? fileDownloaded,
    required gd.DriveApi drive,
    required Directory dirDatabase,
    required List<String> finalPath}) async {

    List<Map<String, dynamic>> lstJson = [];

    try {
      files.forEach((g_file) async {

        //download file data from file id
        fileDownloaded = (await drive.files
            .get(g_file.id!, downloadOptions: gd.DownloadOptions.fullMedia)) as gd.Media?;

        List<int> dataStore = [];
        await fileDownloaded!.stream.listen((data) {
          dataStore.addAll(data);

          _setState(() {
            //Progress Show
            if(fileDownloaded!.length != null) {
              // print("g_file.size -> ${g_file.size}");
              progress = dataStore.length / int.parse(g_file.size!);
            }
          });

        }, onDone: () async {
          setState(() {
            file_name = g_file.name!;
          });
          // print("file_name -> ${g_file.name}");

          if(g_file.name == "filePaths.txt"){
            File saveFile = File('${dirDatabase.path}/${g_file.name}');
            saveFile.writeAsBytes(dataStore);

            String paths = await saveFile.readAsString();
            finalPath = paths.replaceAll("[", "").replaceAll("]", "").split(", ");
          }

          //Store google file name and data into json
          var googleFileJson = GoogleFile(gFileName: g_file.name, gFileData: dataStore).toMap();
          //Add json into list
          lstJson.add(googleFileJson);

          print("g_file.name -> ${g_file.name}");
          print("files.length -> ${files.length}");
          print("lstJson.length -> ${lstJson.length}");

          //When Data fetch reach to last element this will execute
          if(files.length == lstJson.length) {
            lstJson.forEach((json) async {
              String fileNAme = json["gFileName"];

              List<int> fileDAta = json["gFileData"];
              //find index of current json from list of Paths
              var pathindex = finalPath.indexWhere((element) {
                return element.split("/").last == fileNAme;
              });

              //index -1 = it is not file
              if(pathindex == -1) {
                finalPath.forEach((element) async {
                  if(FileSystemEntity.isDirectorySync(element)) {
                    if(!await Directory(element).exists()){
                      await Directory(element).create(recursive: true);
                    }
                  }
                });
              } else {
                // print('finalPath file-> ${finalPath[pathindex]}');
                String parentFolder = finalPath[pathindex].replaceAll("/${finalPath[pathindex].split("/").last}", "");
                if(!await Directory(parentFolder).exists()) {
                  await Directory(parentFolder).create(recursive: true).whenComplete(() {
                    File finalFile = File(finalPath[pathindex]);
                    finalFile.writeAsBytesSync(fileDAta);
                  });
                } else {
                  File finalFile = File(finalPath[pathindex]);
                  finalFile.writeAsBytesSync(fileDAta);
                }
              }

              if(json == lstJson.last) {
                print('last file restored');
                // isDownloading = false;
                Navigator.pop(_context);
                progress = 1;

                setState(() {});
                _flushbar(msg: "Restore Successfully").show(context);
              }
            });
          }

        }, onError: (error) {
          print('Download drive file error -> $error');
          setState(() {
            Navigator.pop(_context);
            _flushbarError(msg: "Please try again!! file restoration failed").show(context);
            isDownloading = false;
          });

        });

      });
    } catch(e) {
      print(e);
    }

  }

  onPressRestore({required BuildContext context, required CoreNotifier coreNotifier, required GoogleSignInProvider signinNotifier}) async {
    restoreDialogeBox(context);


    try {
      isDownloading = true;
      setState(() {});

      gd.DriveApi drive = gd.DriveApi(await gDrive.clientAuth());
      String? folderId = await gDrive.getFolderID(drive);

      Directory dirDatabase = Directory("/storage/emulated/0/Akshar Notes/database");
      gd.Media? fileDownloaded;
      List<String> finalPath = [];

      //listing all files name
      await drive.files.list(spaces: 'drive', q: "'$folderId' in parents", $fields: "files(id, name, size)").then((value) {
        List<gd.File> files = value.files!;

        if(files.isEmpty) {
          print("files are empty");
          toast("Your Drive folder is empty");
          isDownloading = false;
          Navigator.pop(_context);
          setState(() {});

        } else {
          logger.log("files are not empty");

          downloadGoogleDriveFiles(drive: drive, dirDatabase: dirDatabase, files: files, finalPath: finalPath, fileDownloaded: fileDownloaded);
        }

      });
    } catch (e) {
      print("restore error -> $e");
      isDownloading = false;
      toast("Google connection timeout!! Please signin again");
      signinNotifier.logout();
      setState(() {});
    }

  }

  //For dialogebox
  late StateSetter _setState;
  late StateSetter _setStateBackup;
  late BuildContext _context;

  @override
  Widget build(BuildContext context) {
    var coreNotifier = Provider.of<CoreNotifier>(context);
    var signinNotifier = Provider.of<GoogleSignInProvider>(context);
    final percentage = progress * 100;
    final uploadPercentage = uploadProgress * 100;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text("All Backup"),
          ),
          body: Column(
            children: [
              bakupContainer(
                coreNotifier: coreNotifier,
                signinNotifier: signinNotifier
              ),
              Divider(color: Colors.grey),
              restoreContainer(
                  coreNotifier: coreNotifier,
                  signinNotifier: signinNotifier
              ),
            ],
          )
        ),
        // isUploading ? Scaffold(
        //   backgroundColor: Colors.transparent,
        //   body: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 50),
        //     color: Colors.black87,
        //     width: MediaQuery.of(context).size.width,
        //     height: MediaQuery.of(context).size.height,
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Text("Do not close. Please wait! Backuping files ..."),
        //         SizedBox(height: 25),
        //         Container(
        //             height: 35,
        //             child: LiquidLinearProgressIndicator(
        //               borderRadius: 6,
        //               value: uploadProgress,
        //               backgroundColor: Colors.white70,
        //               valueColor: AlwaysStoppedAnimation(Colors.blue),
        //               center: Text("${uploadPercentage.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.w500),),
        //             )
        //         ),
        //       ],
        //     ),
        //     alignment: Alignment.center,
        //   ),
        // ) : SizedBox.shrink(),
        // isDownloading ? Scaffold(
        //   backgroundColor: Colors.transparent,
        //   body: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 50),
        //     color: Colors.black87,
        //     width: MediaQuery.of(context).size.width,
        //     height: MediaQuery.of(context).size.height,
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Text("Please wait! Restoring $file_name ...", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500),),
        //         SizedBox(height: 25),
        //         Container(
        //           height: 45,
        //           width: 45,
        //           child: CircularProgressIndicator(
        //             strokeWidth: 5.5,
        //             backgroundColor: Colors.white,
        //           ),
        //           // child: LiquidLinearProgressIndicator(
        //           //   borderRadius: 6,
        //           //   value: progress,
        //           //   backgroundColor: Colors.white70,
        //           //   valueColor: AlwaysStoppedAnimation(Colors.blue),
        //           //   center: Text("${percentage.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),),
        //           // )
        //         ),
        //       ],
        //     ),
        //     alignment: Alignment.center,
        //   ),
        // ) : SizedBox.shrink()
      ],
    );
  }

  Future<void> backupDialogeBox(BuildContext context) {
    return showDialog(
        barrierDismissible: false,
        barrierColor: Colors.black87,
        context: context,
        builder: (context) {
          _context = context;
          return AlertDialog(
              contentPadding: EdgeInsets.zero,
              backgroundColor: Colors.grey.shade900,
              content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    _setState = setState;
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text("Please Wait", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                          SizedBox(height: 10),
                          Divider(),
                          SizedBox(height: 10),
                          Text("Do not close!!  Files are backuping up ...", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w400)),
                          SizedBox(height: 25),
                          Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: LiquidLinearProgressIndicator(
                                borderRadius: 6,
                                value: uploadProgress,
                                backgroundColor: Colors.white70,
                                valueColor: AlwaysStoppedAnimation(Colors.blue),
                                center: Text("${(uploadProgress * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),),
                              )
                          ),
                          SizedBox(height: 25),
                        ],
                      ),
                    );
                  }
              )
          );
        }
    );
  }

  Future<void> restoreDialogeBox(BuildContext context) {
    return showDialog(
        barrierDismissible: false,
        barrierColor: Colors.black87,
        context: context,
        builder: (context) {
          _context = context;
          return AlertDialog(
              contentPadding: EdgeInsets.zero,
              backgroundColor: Colors.grey.shade900,
              content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    _setState = setState;
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text("Please Wait", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                          SizedBox(height: 10),
                          Divider(),
                          SizedBox(height: 10),
                          Text("Do not close!!  Files are restoring ...", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w400)),
                          SizedBox(height: 25),
                          Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: LiquidLinearProgressIndicator(
                                borderRadius: 6,
                                value: progress,
                                backgroundColor: Colors.white70,
                                valueColor: AlwaysStoppedAnimation(Colors.blue),
                                center: Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),),
                              )
                          ),
                          SizedBox(height: 25),
                        ],
                      ),
                    );
                  }
              )
          );
        }
    );
  }

  Widget bakupContainer({required GoogleSignInProvider signinNotifier,required CoreNotifier coreNotifier}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.backup, color: Colors.grey.shade100, size: 22),
            SizedBox(width: 20),
            Container(
              alignment: Alignment.centerRight,
              width: MediaQuery.of(context).size.width * 0.77,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),
                  Text("Sync Data", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),),
                  SizedBox(height: 7),
                  Wrap(
                    children: [
                      Text("Back up your all files and folders to Google Drive. "
                          "You can restore them when you reinstall Akshar Notes on current device or another device. "
                          "Your all files and folders will also restore to your phone's internal storage.",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          primary: Colors.black,
                          padding: const EdgeInsets.all(10)
                      ),
                      child: Text("BACKUP NOW"),
                      // onPressed: () {}
                      onPressed: () {
                        final _user = FirebaseAuth.instance.currentUser;
                        if(_user == null) {
                          signinNotifier.login(context).whenComplete(() async {

                            if(_user != null) {
                              Future.delayed(const Duration(seconds: 2), () {
                                onPressBackup(context: context, coreNotifier: coreNotifier);
                              });
                            }

                          });
                        } else {
                          onPressBackup(context: context, coreNotifier: coreNotifier);
                        }
                      }
                  )
                ],
              ),
            )
          ],
        )
    );
  }

  Widget restoreContainer({required GoogleSignInProvider signinNotifier,required CoreNotifier coreNotifier}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.add_to_drive_sharp, color: Colors.grey.shade100, size: 22),
            SizedBox(width: 20),
            Container(
              alignment: Alignment.centerRight,
              width: MediaQuery.of(context).size.width * 0.77,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),
                  Text("Restore Data", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),),
                  SizedBox(height: 7),
                  Wrap(
                    children: [
                      Text("Restore your all files and folders from Google Drive. "
                          "This will restore all your data as it is into your phone's internal storage.",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          primary: Colors.black,
                          padding: const EdgeInsets.all(10)
                      ),
                      child: Text("RESTORE"),
                      onPressed: () {
                        final _user = FirebaseAuth.instance.currentUser;
                        if(_user == null) {
                          signinNotifier.login(context).whenComplete(() async {

                            if(_user != null) {
                              Future.delayed(const Duration(seconds: 1), () {
                                onPressRestore(context: context, coreNotifier: coreNotifier, signinNotifier: signinNotifier);
                              });
                            }

                          });
                        } else {
                          onPressRestore(context: context, coreNotifier: coreNotifier, signinNotifier: signinNotifier);
                        }
                      }
                  )
                ],
              ),
            )
          ],
        )
    );
  }

}
