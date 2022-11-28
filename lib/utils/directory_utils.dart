// ignore_for_file: import_of_legacy_library_into_null_safe
import 'package:filesize/filesize.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class Directory_Utils {
  // final List<Color> _lstColors = [Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.tealAccent, Colors.brown, Colors.blueGrey, Colors.amberAccent];

  //FILE FOLDERS ICONS AND SIZE
  fileTypeImageGrid(String _path, int index){
    var _type = path.extension(_path);
    final nameFile = path.split('/').last;

    if(FileSystemEntity.isDirectorySync(_path)) {
      return Image.asset("assets/icons/notebook.png", fit: BoxFit.fill, color: Colors.primaries[index]);
    } else {
      if(_type == ".jpg" || _type == ".jpeg" || _type == ".JPEG" || _type == ".png" || _type == ".svg"){
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 0.7),
                borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 9),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                File(_path),
                fit: BoxFit.cover,
                errorBuilder: (
                    BuildContext context,
                    Object? error,
                    StackTrace? stackTrace,
                    ) {
                  return Container(
                    color: Colors.grey,
                    child: const Center(
                      child: Text('Error load image', textAlign: TextAlign.center),
                    ),
                  );
                },
              ),
            )
        );
      } else if(_type == ".mp4" || _type == ".mkv" || _type == ".MOV") {
        return SvgPicture.asset("assets/icons/video.svg", fit: BoxFit.fill);
      } else if(_type == ".mp3" || _type == ".ogg" || _type == ".aac") {
        return Image.asset("assets/icons/music.png", fit: BoxFit.cover);
      } else if(_type == ".pdf") {
        return Image.asset("assets/icons/black-pdf.png", fit: BoxFit.cover);
      } else if(_type == ".apk") {
        return SvgPicture.asset("assets/icons/android.svg", fit: BoxFit.cover);
      } else if(_type == ".xml" || _type == ".xlsx") {
        return Image.asset("assets/icons/xml.png", fit: BoxFit.cover);
      } else if(_type == ".zip") {
        return SvgPicture.asset("assets/icons/zip.svg", fit: BoxFit.fill);
      } else if(_type == ".txt" || _type == ".text") {
        return Image.asset("assets/icons/black-txt.png", fit: BoxFit.cover);
      } else if(_type == ".docx" || _type == ".dot" || _type == ".dotx") {
        return SvgPicture.asset("assets/icons/word.svg", fit: BoxFit.fill);
      } else if(_type == ".URL") {
        return Image.asset("assets/icons/internet.png", fit: BoxFit.fitHeight);
      } else {
        return Image.asset("assets/icons/black-unknown.png", fit: BoxFit.cover);
      }
    }

  }

  fileTypeImageList(String _path, int index){
    var _type = path.extension(_path);

    if(FileSystemEntity.isDirectorySync(_path)) {
      return Image.asset("assets/icons/notebook.png", fit: BoxFit.fill, color: Colors.primaries[index]);
    } else {
      if(_type == ".jpg" || _type == ".jpeg" || _type == ".JPEG" || _type == ".png" || _type == ".svg"){
        return Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 0.4),
                borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_path),
                fit: BoxFit.cover,
                errorBuilder: (
                    BuildContext context,
                    Object? error,
                    StackTrace? stackTrace,
                    ) {
                  return Container(
                    color: Colors.grey,
                    width: 100,
                    height: 100,
                    child: const Center(
                      child: Text('Error load image', textAlign: TextAlign.center),
                    ),
                  );
                },
              ),
            )
        );
      } else if(_type == ".mp4" || _type == ".mkv" || _type == ".MOV") {
        return SvgPicture.asset("assets/icons/video.svg", fit: BoxFit.fill);
      } else if(_type == ".mp3" || _type == ".ogg" || _type == ".aac") {
        return Image.asset("assets/icons/music.png", fit: BoxFit.fill);
      } else if(_type == ".pdf") {
        return Image.asset("assets/icons/black-pdf.png", fit: BoxFit.fill);
      } else if(_type == ".apk") {
        return SvgPicture.asset("assets/icons/android.svg", fit: BoxFit.cover);
      } else if(_type == ".xml"|| _type == ".xlsx") {
        return Image.asset("assets/icons/xml.png", fit: BoxFit.fill);
      } else if(_type == ".zip") {
        return SvgPicture.asset("assets/icons/zip.svg", fit: BoxFit.fill);
      } else if(_type == ".txt" || _type == ".text") {
        return Image.asset("assets/icons/black-txt.png", fit: BoxFit.fill);
      } else if(_type == ".docx" || _type == ".dot" || _type == ".dotx") {
        return SvgPicture.asset("assets/icons/word.svg", fit: BoxFit.fill);
      } else if(_type == ".URL") {
        return Image.asset("assets/icons/internet.png", fit: BoxFit.fitHeight);
      } else {
        return Image.asset("assets/icons/black-unknown.png", fit: BoxFit.fill);
      }
    }

  }


  // FILE/FOLDER SIZE
  Widget fileFolderSize(String path,Map<String, int> dir, TextStyle textStyle) {
    var tempFile = File(path);
    if(FileSystemEntity.isDirectorySync(path)) {
      return Text("${dir["fileNum"].toString()} items |  ${filesize(dir["totalSize"].toString())}", style: textStyle);
    } else {
      return Text(filesize(tempFile.lengthSync()), style: textStyle);
    }

  }

  //ITEMS COUNT
  Map<String, int> dirSize(String dirPath){
    int fileNum = 0;
    int totalSize = 0;

    var dir = Directory(dirPath);
    try {
      if(dir.existsSync()){
        dir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if(entity is File) {
            fileNum++;
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      print("file length error -> ${e.toString()}");
    }
    return {'fileNum' : fileNum, 'totalSize' : totalSize};
  }

}