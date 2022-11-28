import 'dart:io';
import 'package:filemanager_app/Models/notification_file.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {

  Future initNotificationFileDB() async {
    //Added custom path
    Directory dir = Directory("/storage/emulated/0/Akshar Notes/database");
    String path = dir.path;

    String checkExistPath = join(path, "MYNotificationFileDB.db");
    final exist = await databaseExists(checkExistPath);

      final database = await openDatabase(
          join(path, "MYNotificationFileDB.db"),
          onCreate: (db, version) async {
            await db.execute(
                "CREATE TABLE MYNotificationFileDB("
                    "fileId INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "fileName TEXT,"
                    "filePath TEXT,"
                    "title TEXT NOT NULL,"
                    "description TEXT,"
                    "dateTime TEXT NOT NULL,"
                    "notificationId TEXT NOT NULL,"
                    "isFile INTEGER,"
                    "isComplete INTEGER)"
            );
          },
          version: 7
      );

    return database;
  }

  //INSERT DATA
  Future<bool> insertNotificationFileData(NotificationFile file) async {
    final Database db = await initNotificationFileDB();
    db.insert("MYNotificationFileDB", file.toMap());
    return true;
  }

  //GET ALL DATA
  Future<List<NotificationFile>> getAllNotificationFileData() async {
    final Database db = await initNotificationFileDB();
    final List<Map<String, Object?>> datas = await db.query("MYNotificationFileDB");
    return datas.map((e) => NotificationFile.fromMap(e)).toList();
  }

  //GET DATA FROM FILE NAME
  Future<List<NotificationFile>> getNotificationFileNameData(String fileName) async {
    final Database db = await initNotificationFileDB();
    final List<Map<String, Object?>> datas = await db.query("MYNotificationFileDB", where: "fileName = ?", whereArgs: [fileName]);
    return datas.map((e) => NotificationFile.fromMap(e)).toList();
  }

  //GET DATA FROM FILE ID
  Future<List<NotificationFile>> getNotificationFileIdData(int notificationId) async {
    final Database db = await initNotificationFileDB();
    final List<Map<String, Object?>> datas = await db.query("MYNotificationFileDB", where: "notificationId = ?", whereArgs: [notificationId]);
    return datas.map((e) => NotificationFile.fromMap(e)).toList();
  }

  //UPDATE DATA
  Future<int> updateNotificationFileData(NotificationFile file) async {
    final Database db = await initNotificationFileDB();
    return await db.update("MYNotificationFileDB", file.toMap(), where: "fileId = ?", whereArgs: [file.fileId]);
  }

  //DELETE DATA
  Future<int> deleteNotificationFileData(int fileId) async {
    final Database db = await initNotificationFileDB();
    return await db.delete("MYNotificationFileDB", where: "fileId = ?", whereArgs: [fileId]);
  }

  //DELETE ALL DATA
  Future<int> deleteAllNotificationFileData() async {
    final Database db = await initNotificationFileDB();
    return await db.delete("MYNotificationFileDB");
  }


}

