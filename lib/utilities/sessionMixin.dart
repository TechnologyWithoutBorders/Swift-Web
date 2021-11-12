import 'package:flutter/material.dart';

import 'package:teog_swift/main.dart';
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;

mixin SessionMixin<T> on State {
  @override
  void initState() {
    Prefs.checkLogin().then((role) {
      
      if(role == Constants.role_invalid) {
        Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
      }
    });

    super.initState();
  }
}