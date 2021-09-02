import 'dart:convert';
import 'package:teog_swift/main.dart';

import 'package:flutter/material.dart';

import 'networkFunctions.dart' as Comm;
import 'preference_manager.dart' as Prefs;
import 'deviceInfo.dart';
import 'deviceStates.dart' as DeviceState;
import 'package:teog_swift/previewDeviceInfo.dart';
import 'package:teog_swift/deviceInfoScreen.dart';

class DashboardScreen extends StatefulWidget {
  static const String route = '/dashboard';

  DashboardScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DashboardScreen> {
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
        children: [Card(
          child: Padding(padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("TODO"),
                SizedBox(height: 500, width: 600, child:
                  Scrollbar(isAlwaysShown: true,
                    controller: _scrollController,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _devices.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          leading: Container(width: 30, height: 30, color: _devices[index].report.getColor(),
                            child: Padding(padding: EdgeInsets.all(3.0),
                              child: Row(children: [
                                  Icon(_devices[index].report.getIconData()),
                                ]
                              )
                            )
                          ),
                          title: Text(_devices[index].device.type),
                          subtitle: Text(_devices[index].device.manufacturer + " " + _devices[index].device.model),
                          trailing: Text(_devices[index].device.location),
                          onTap: () => _openDeviceById(_devices[index].device.id)
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) => const Divider(),
                    ),
                  ),
                ),
                TextButton(
                  child: Text('Create new device?'),
                ),
              ]
            )
          ),
        )]
      )
      )));
  }
}
