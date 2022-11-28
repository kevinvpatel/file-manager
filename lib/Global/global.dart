import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


BoxDecoration decoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(color: Colors.black26.withOpacity(0.3), blurRadius: 3, offset: const Offset(1, 1))
    ],
    color: Colors.white54
);

bool isSearchOn = false;
List<String> driveFileName = [];

var uid;