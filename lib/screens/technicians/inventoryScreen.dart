import 'package:flutter/material.dart';
import 'package:teog_swift/screens/technicians/technicianDeviceScreen.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/shortDeviceInfo.dart';
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

  List<ShortDeviceInfo> _devices = [];
  List<ShortDeviceInfo> _preFilteredDevices = [];
  List<ShortDeviceInfo> _displayedDevices = [];

  final _filterTextController = TextEditingController();

  bool _manualButtonDisabled = false;

  @override
  void initState() {
    super.initState();

    Comm.getDevices().then((devices) {//TODO: catch Exception
      setState(() {
        _listTitle = "Number of devices: ";
        _devices = devices;
        _preFilteredDevices = List.from(_devices);
        _displayedDevices = List.from(_devices);
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

  void _showAllDevices() {
    Comm.getDevices().then((devices) {//TODO: catch Exception
      setState(() {
        _filterTextController.clear();
        _listTitle = "Number of devices: ";
        _devices = devices;
        _preFilteredDevices = List.from(_devices);
        _displayedDevices = List.from(_devices);
      });
    });
  }

  void _checkManuals() async {
    setState(() {
      _manualButtonDisabled = true;
      _filterTextController.clear();
      _preFilteredDevices.clear();
      _displayedDevices.clear();
      _listTitle = "Number of devices without manuals: ";
    });

    int counter = 0;

    for(ShortDeviceInfo deviceInfo in _devices) {
      try {
        List<String> documents = await Comm.retrieveDocuments(deviceInfo.device.manufacturer, deviceInfo.device.model);

        if(documents.length == 0) {
          _preFilteredDevices.add(deviceInfo);
          setState(() {
            _displayedDevices.add(deviceInfo);
          });
        }
      } catch(e) {//TODO specific exception
        _preFilteredDevices.add(deviceInfo);
        setState(() {
          _displayedDevices.add(deviceInfo);
        });
      }

      counter++;

      setState(() {
        _progress = counter/_devices.length;
      });
    }

    setState(() {
      _manualButtonDisabled = false;
    });
  }

  void _filter(String text) {
    setState(() {
      _displayedDevices.clear();

      if(text.isNotEmpty) {
        _listTitle = "Number of devices matching the filter: ";
      } else {
        _listTitle = "Number of devices: ";
      }
    });

    List<String> filterTexts = text.trim().split(" ");

    for(ShortDeviceInfo deviceInfo in _preFilteredDevices) {
      HospitalDevice device = deviceInfo.device;

      bool skip = false;

      for(String filterText in filterTexts) {
        if(device.type.toLowerCase().contains(filterText) || device.manufacturer.toLowerCase().contains(filterText) || device.model.toLowerCase().contains(filterText)) {
          continue;
        } else {
          skip = true;
        }
      }

      if(!skip) {
        setState(() {
          _displayedDevices.add(deviceInfo);
        });
      }
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
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Text("Show all devices"),
                        onPressed: _manualButtonDisabled ? null : () => _showAllDevices(),
                      ),
                      ElevatedButton(
                        child: Text("Show devices without manuals"),
                        onPressed: _manualButtonDisabled ? null : () => _checkManuals(),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _filterTextController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'filter...'
                    ),
                    onChanged: (text) => _filter(text.trim().toLowerCase()),
                    enabled: !_manualButtonDisabled
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _progress
                  ),
                  SizedBox(height: 10),
                  Text(_listTitle + _displayedDevices.length.toString()),
                  Flexible(child: Padding(padding: EdgeInsets.all(10.0),
                    child: Scrollbar(isAlwaysShown: true,
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(3),
                        itemCount: _displayedDevices.length,
                        itemBuilder: (BuildContext context, int index) {
                          ShortDeviceInfo deviceInfo = _displayedDevices[index];

                          return ListTile(
                            leading: Container(width: 30, height: 30, color: DeviceState.getColor(deviceInfo.report.currentState),
                              child: Padding(padding: EdgeInsets.all(3.0),
                                child: Row(children: [
                                    Icon(DeviceState.getIconData(deviceInfo.report.currentState))
                                  ]
                                )
                              )
                            ),
                            title: Text(deviceInfo.device.type),
                            subtitle: Text(deviceInfo.device.manufacturer + " " + deviceInfo.device.model),
                            trailing: Text(deviceInfo.device.location),
                            onTap: () => _openDeviceById(deviceInfo.device.id)
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