import 'package:flutter/material.dart';

import 'package:teog_swift/main.dart';
import 'preferenceManager.dart' as Prefs;

mixin SessionMixin<T> on State {
  @override
  void initState() {
    Prefs.checkLogin().then((success) {
      
      if(!success) {
        Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
      }
    });

    super.initState();
  }
}