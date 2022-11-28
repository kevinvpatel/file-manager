import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Flushbars{

  late Flushbar flushbarComplete;
  late Flushbar flushbarError;

  Flushbars(){
    flushbars();
  }

  Flushbar<dynamic> errorFlushbar(String error, Duration? duration){
    flushbarError = Flushbar(
        showProgressIndicator: false,
        boxShadows: const [
          BoxShadow(
              color: Colors.black45,
              offset: Offset(3, 3),
              blurRadius: 3
          )
        ],
        mainButton: TextButton(
          onPressed: () { flushbarError.dismiss(true); },
          child: const Text("Dismiss"),
        ),
        icon: const Icon(Icons.info_outline, color: Colors.white),
        message: error,
        duration: duration ?? const Duration(milliseconds: 2900),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8)
    );

    return flushbarError;
  }


  void flushbars(){
      flushbarComplete = Flushbar(
          showProgressIndicator: false,
          boxShadows: const [
            BoxShadow(
                color: Colors.black45,
                offset: Offset(3, 3),
                blurRadius: 3
            )
          ],
          icon: const Icon(Icons.cloud_done_outlined, color: Colors.green),
          message: "Files Uploaded",
          duration: const Duration(milliseconds: 1900),
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8)
      );

  }


}