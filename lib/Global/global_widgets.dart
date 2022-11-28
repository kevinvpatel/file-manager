import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';

Future<Object?> dialogeMessageBox(BuildContext context, {Widget? title, required EdgeInsetsGeometry edgeInsets, required List<Widget> children, List<Widget>? buttons}) {
  return showAnimatedDialog(
      alignment: Alignment.center,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title,
          contentPadding: edgeInsets,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          actions: buttons,
        );
      },
      barrierColor: Colors.black54,
      animationType: DialogTransitionType.scale,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 600)
  );
}

toast(String text) {
  BotToast.showText(
      textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
      text: text,
      duration: const Duration(milliseconds: 2500),
      contentColor: Colors.grey.shade900.withOpacity(0.95),
      contentPadding: const EdgeInsets.all(10)
  );
}


