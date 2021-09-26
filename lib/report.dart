import 'package:flutter/material.dart';

import 'package:teog_swift/deviceState.dart';

class Report {
  final int currentState;
  final String created;

  Report({this.currentState, this.created});

  String getStateString() {
    switch(currentState) {
      case DeviceState.working: return "working";
      case DeviceState.maintenance: return "maintenance";
      case DeviceState.broken: return "repair needed";
      case DeviceState.inProgress: return "work in progress";
      case DeviceState.salvage: return "salvage";
      case DeviceState.limitations: return "working with limitations";
      default: return "unknown";
    }
  }

  Color getColor() {
    switch(currentState) {
      case DeviceState.working: return Colors.green;
      case DeviceState.maintenance: return Colors.blue;
      case DeviceState.broken: return Colors.orange;
      case DeviceState.inProgress: return Colors.lightGreen;
      case DeviceState.salvage: return Colors.red;
      case DeviceState.limitations: return Colors.redAccent;
      default: return Colors.yellow;
    }
  }

  IconData getIconData() {
    switch(currentState) {
      case DeviceState.working: return Icons.check;
      case DeviceState.maintenance: return Icons.access_alarm;
      case DeviceState.broken: return Icons.build;
      case DeviceState.inProgress: return Icons.hourglass_empty;
      case DeviceState.salvage: return Icons.block;
      case DeviceState.limitations: return Icons.warning;
      default: return null;
    }
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      currentState: json['currentState'],
      created: json['created'],//TODO UTC->local
    );
  }
}