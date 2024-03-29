import 'package:flutter/material.dart';

class DeviceState {
  static const int working = 0;
  static const int maintenance = 1;
  static const int broken = 2;
  static const int inProgress = 3;
  static const int salvage = 4;
  static const int limitations = 5;

  static const names = ["working", "maintenance", "broken", "work in progress", "beyond repair", "working with limitations"];
  static const colors = [Colors.green, Colors.blue, Colors.orange, Colors.lightGreen, Colors.red, Colors.redAccent];
  static const icons = [Icons.check, Icons.access_alarm, Icons.build, Icons.hourglass_empty, Icons.block, Icons.warning];

  static String getStateString(final int state) {
    return names[state];
  }

  static Color getColor(final int state) {
    return colors[state];
  }

  static IconData getIconData(final int state) {
    return icons[state];
  }
}