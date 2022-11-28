import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filemanager_app/Global/global.dart';
import 'package:filemanager_app/Global/global_widgets.dart';
import 'package:filemanager_app/notifiers/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticateClient extends http.BaseClient {
  final Map<String, String> headers;

  AuthenticateClient(this.headers);

  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(headers));
  }

}

class GoogleDrive {
  late SharedPreferences prefs;


  void NotifyBegin({required String fileName}) async {
    print('NotifyBegin...');
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 0101010,
          channelKey: 'upload',
          title: 'File uploading',
          body: fileName,
          notificationLayout: NotificationLayout.ProgressBar,
        ),
    );
  }

  void NotifyDismiss() async {
    print('NotifyDismiss...');
    await AwesomeNotifications().dismiss(0101010);
  }


  Future<String?> getFileID(gd.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String fileName = "filePaths.txt";

    try {
      final found = await driveApi.files.list(q: "mimeType != '$mimeType' and name = '$fileName'", $fields: "files(id, name)",);
      final files = found.files;
      if(files == null) {
        print('filePath.txt File not found....');
        return null;
      }

      return files.first.id;

    } catch(e) {
      print(e);
    }

  }

  Future<String?> getFolderID(gd.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "Akshar Notes";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if(files == null) {
        print('Drive Folder not found....');
        return null;
      }

      //Check if folder exist
      if(files.isNotEmpty) {
        return files.first.id;
      }

      //Create a folder
      var folder = gd.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print('drive folder id -> ${folderCreation.id}');
      return folderCreation.id;

    } catch(e) {
      print(e);
      return null;
    }

  }


  Future<AuthenticateClient> clientAuth() async {
    prefs = await SharedPreferences.getInstance();

    var mapAuthHeaders = Map<String, String>.from(
        json.decode(prefs.getString("authHeaders")!));
    print("mapAuthHeaders @ $mapAuthHeaders");

    final authenticateClient = AuthenticateClient(mapAuthHeaders);
    return authenticateClient;
  }


  Future uploadThroughPick(FilePickerResult result, Directory currentDir, CoreNotifier coreNotifier, BuildContext context) async {

    //Store AuthHeader in SharedPrefs from google login
    gd.DriveApi drive = gd.DriveApi(await clientAuth());
    gd.File fileToUpload = gd.File();
    final folderId = await getFolderID(drive);

    for (PlatformFile item in result.files) {
      NotifyBegin(fileName: item.name);

      var filePath = currentDir.path + "/" + item.name;

      //CODE TO CREATE FILE ON DRIVE
      var file = File(filePath);
      fileToUpload.name = item.name;
      fileToUpload.parents = [folderId!];

      try {
        //Code to upload files on google drive
        var response = await drive.files.create(
            fileToUpload,
            uploadMedia: gd.Media(file.openRead(), item.size)
        ).then((value) {
          NotifyDismiss();
          toast('${value.name} uploaded on drive');
        });


        //Code to get all files from google drive
        driveFileName.clear();
        await drive.files.list().then((value) {
          value.files!.forEach((element) {
            if(!driveFileName.contains(element.name)){
              driveFileName.add(element.name!);
            }
          });
        }).whenComplete(() {
          coreNotifier.reload();
        });

        print("uploaded response ${response.name}");
      } catch(e) {
        NotifyDismiss();
        // _flushbars.errorFlushbar('File uploading failed check internet connection', const Duration(milliseconds: 2900)).show(context);
        print("drive upload error @ $e");
      }
    }
  }



  Future uploadFile(FileSystemEntity item, BuildContext context, CoreNotifier coreNotifier) async {

    //Store AuthHeader in SharedPrefs from google login
    gd.DriveApi drive = gd.DriveApi(await clientAuth());
    gd.File fileToUpload = gd.File();
    final folderId = await getFolderID(drive);

    //CODE TO CREATE FILE ON DRIVE
    var file = File(item.path);
    fileToUpload.name = item.path.split("/").last;
    fileToUpload.parents = [folderId!];

    try {
      NotifyBegin(fileName: item.path.split("/").last);

      //Code to upload files on google drive
      var response = await drive.files.create(
          fileToUpload,
          uploadMedia: gd.Media(file.openRead(), file.lengthSync())
      ).then((value) {
        NotifyDismiss();
        toast('${value.name} uploaded on drive');
      });

      //Code to get all files from google drive
      driveFileName.clear();
      await drive.files.list().then((value) {
        value.files!.forEach((element) {
          if(!driveFileName.contains(element.name)){
            driveFileName.add(element.name!);
          }
        });
      }).whenComplete(() => coreNotifier.reload());

      print("uploaded response ${response.name}");
    } catch(e) {
      NotifyDismiss();
      // _flushbars.errorFlushbar('File uploading failed check internet connection', const Duration(milliseconds: 2900)).show(context);
      print("drive upload error @ $e");
    }

  }

}


//For WebView Login
// var clientID = "353864294113-eefjfj4h4n9b1dupl2fbgd7dmdkvojfm.apps.googleusercontent.com";
// var clientSecret = "HFCc8AO3TV9evhQMxjvE2CgX";
// var _scope = [gd.DriveApi.driveFileScope];
//
// class GoogleDrive {
//   final storage = SecretStorage();
//
//   //Authenticate HTTP CLIENT
//   Future<http.Client> getHttpClient() async {
//
//     //Get Credentials
//     var credentials = await storage.getCredentials();
//     if(credentials == null) {
//       var authClient = await clientViaUserConsent(ClientId(clientID, clientSecret), _scope, (url) async {
//         print("url  @ $url");
//
//         launch(url);
//       });
//       print("accessToken @ ${authClient.credentials.accessToken}");
//       print("refreshToken @ ${authClient.credentials.refreshToken}");
//       storage.saveCredentials(authClient.credentials.accessToken, authClient.credentials.refreshToken!);
//       return authClient;
//     } else {
//       print("credential expiry -> ${credentials["expiry"]}");
//       //Already Authenticated
//       return authenticatedClient(http.Client(), AccessCredentials(
//           AccessToken(credentials["type"], credentials["data"], DateTime.parse(credentials["expiry"])),
//           credentials["refreshToken"],
//           _scope
//       ));
//     }
//   }
//
//   //UPLOAD FILE
//   Future upload(FilePickerResult result, Directory currentDir) async {
//     for(PlatformFile fileItem in result.files) {
//       var filePath = currentDir.path + "/" + fileItem.name;
//       var file = File(filePath);
//       var client = await getHttpClient();
//       var drive = gd.DriveApi(client);
//       var response = await drive.files.create(
//           gd.File()..name = fileItem.name,
//           uploadMedia: gd.Media(file.openRead(), file.lengthSync())
//       );
//       print("response -> $response");
//       return response;
//     }
//
//   }
//
// }