import 'dart:convert';
import 'package:teog_swift/main.dart';

import 'package:flutter/material.dart';

import 'networkFunctions.dart' as Comm;
import 'preference_manager.dart' as Prefs;
import 'deviceInfo.dart';
import 'deviceStates.dart' as DeviceState;
import 'package:teog_swift/previewDeviceInfo.dart';
import 'package:teog_swift/deviceInfoScreen.dart';

import 'package:qr_flutter/qr_flutter.dart';

class CodeGenerationScreen extends StatefulWidget {
  static const String route = '/code_generation';

  CodeGenerationScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<CodeGenerationScreen> {
  final _scrollController = ScrollController();

  List<DeviceInfo> _devices = [];

  @override
  void initState() {
    super.initState();

    Comm.getTodoDevices().then((devices) {//TODO catch Exception
      setState(() {
        _devices = devices;
      });
    });
  }

  void _openDeviceById(int id) {
    Comm.fetchDevice(id).then((deviceInfo) {//TODO catch Exception
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(deviceInfo: deviceInfo),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(
      child: SizedBox(width: 400, height: 600,
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [QrImage(
          data: "1234567890",
          version: QrVersions.auto,
          size: 200.0)
          ]
          )
          ),
        )
      );
  }
}