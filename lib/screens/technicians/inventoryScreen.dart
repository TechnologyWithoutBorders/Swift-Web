import 'package:flutter/material.dart';
import 'package:teog_swift/screens/technicians/technicianDeviceScreen.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/deviceInfo.dart';
import 'package:teog_swift/screens/deviceInfoScreen.dart';
import 'package:teog_swift/utilities/deviceState.dart';

class InventoryScreen extends StatefulWidget {
  InventoryScreen({Key key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _scrollController = ScrollController();
  double _progress = 0;
  String _listTitle = "";

  List<DeviceInfo> _devices = [];

  @override
  void initState() {
    super.initState();

    Comm.getDevices().then((devices) {//TODO: catch Exception
      setState(() {
        _listTitle = "Number of devices: ";
        _devices = devices;
      });
    });
  }

  void _openDeviceById(int id) {
    Comm.fetchDevice(id).then((deviceInfo) {//TODO: catch Exception
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianDeviceScreen(deviceInfo: deviceInfo),
        )
      );
    });
  }

  void _checkManuals() async {
    setState(() {
      _devices.clear();
      _listTitle = "Number of devices without manuals: ";
    });

    List<DeviceInfo> devices = await Comm.getDevices();

    int counter = 0;

    for(DeviceInfo deviceInfo in devices) {
      try {
        List<String> documents = await Comm.retrieveDocuments(deviceInfo.device.manufacturer, deviceInfo.device.model);

        if(documents.length == 0) {
          _devices.add(deviceInfo);
        }
      } catch(e) {//TODO specific exception
        setState(() {
          _devices.add(deviceInfo);
        });
      }

      counter++;

      setState(() {
        _progress = counter/devices.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  ElevatedButton(
                    child: Text("Check manuals"),
                    onPressed: () => _checkManuals()
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _progress
                  ),
                  SizedBox(height: 10),
                  Text(_listTitle + _devices.length.toString()),
                  Flexible(child: Padding(padding: EdgeInsets.all(10.0),
                    child: Scrollbar(isAlwaysShown: true,
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(3),
                        itemCount: _devices.length,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            leading: Container(width: 30, height: 30, color: DeviceState.getColor(_devices[index].report.currentState),
                              child: Padding(padding: EdgeInsets.all(3.0),
                                child: Row(children: [
                                    Icon(DeviceState.getIconData(_devices[index].report.currentState))
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
                  )),
                ]
              ),
            ),
          )     
        )
      )
    );
  }
}