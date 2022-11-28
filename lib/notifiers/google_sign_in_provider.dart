import 'dart:convert';
import 'package:filemanager_app/Global/Widgets/flushbars.dart';
import 'package:googleapis/drive/v3.dart' as gd;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn.standard(scopes: [
    'email',
    gd.DriveApi.driveFileScope,
    gd.DriveApi.driveAppdataScope
  ]);
  late bool _isSigningIn;

  Flushbars flushbars = Flushbars();
  GoogleSignInProvider(){
    _isSigningIn = false;
  }

  bool get isSigningIn => _isSigningIn;

  set isSigningIn(bool isSigningIn){
    _isSigningIn = isSigningIn;
    notifyListeners();
  }


  Future login(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isSigningIn = true;
    GoogleSignInAccount? user;

    try {
      print("user signing");
      user = await googleSignIn.signIn();
    } catch (onError) {
      print("signin onError -> $onError");
    }

    print("user  @ $user");
    if(user == null){
      isSigningIn = false;
      flushbars.errorFlushbar('Signin Failed', const Duration(milliseconds: 2900)).show(context);
      print("Signin Failed");
      return;
    } else {
      final googleAuth = await user.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _isSigningIn = false;
      //Save User Locally
      var tempUser = json.encode(user.toString());
      prefs.setString("user", tempUser);
      //Save AuthHeader Locally
      user.authHeaders.then((value) {
        var tempAuth = json.encode(value);
        prefs.setString("authHeaders", tempAuth);
      });

      notifyListeners();
    }

  }

  Future logout() async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    _isSigningIn = false;
    notifyListeners();
  }

}