import 'package:flutter/material.dart';
import 'package:teog_swift/screens/organizationFilterView.dart';
import 'package:teog_swift/screens/technicians/technicianDeviceScreen.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/shortDeviceInfo.dart';
import 'package:teog_swift/utilities/report.dart';
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
  Color _colorManual = Colors.blueGrey;
  Color _colorAll = Color(Constants.teog_blue);

  List<ShortDeviceInfo> _devices = [];
  List<ShortDeviceInfo> _preFilteredDevices = [];
  List<ShortDeviceInfo> _displayedDevices = [];

  final _filterTextController = TextEditingController();

  bool _manualButtonDisabled = false;

  static const int filterNone = 0;
  static const int filterMissingManuals = 1;

  OrganizationalUnit _department;
  int _filterType = filterNone;

  @override
  void initState() {
    super.initState();

    _showAllDevices();
  }

  Future<void> _showAllDevices() async {
    List<ShortDeviceInfo> devices = await Comm.getDevices();//TODO: catch Exception
    
    setState(() {
      _filterTextController.clear();
      _filterType = filterNone;
      _listTitle = "Number of devices: ";
      _devices = devices;
      _preFilteredDevices = List.from(_devices);
      _displayedDevices = List.from(_devices);
      _colorManual = Colors.blueGrey;
      _colorAll = Color(Constants.teog_blue);
    });
  }

  void _checkManuals() async {
    setState(() {
      _manualButtonDisabled = true;
      _filterTextController.clear();
      _filterType = filterMissingManuals;
      _preFilteredDevices.clear();
      _displayedDevices.clear();
      _listTitle = "Number of devices with no manual attached: ";
      _colorManual = Color(Constants.teog_blue);
      _colorAll = Colors.blueGrey;
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

  void _filterDepartment() {
    showDialog<OrganizationalUnit>(
      context: context,
      builder: (BuildContext context) {
        return OrganizationFilterView(orgUnit: _department);
      }
    ).then((orgId) => {
      setState(() {
        _department = orgId;
      })
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
                      _department != null ? Text("Department: " + _department.name) : null,
                      OutlinedButton(onPressed: () => _filterDepartment(), child: Text("Select department...")),
                    ]
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      Text("Select devices: "),
                      ElevatedButton(
                        child: Text("All"),
                        onPressed: _manualButtonDisabled ? null : () => _showAllDevices(),
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(_colorAll) )
                      ),
                      ElevatedButton(
                        child: Text("No manual attached"),
                        onPressed: _manualButtonDisabled ? null : () => _checkManuals(),
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(_colorManual) ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _filterTextController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'filter...'
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
                          HospitalDevice device = deviceInfo.device;
                          Report report = deviceInfo.report;

                          return ListTile(
                            leading: Container(width: 30, height: 30, color: DeviceState.getColor(report.currentState),
                              child: Padding(padding: EdgeInsets.all(3.0),
                                child: Row(children: [
                                    Icon(DeviceState.getIconData(report.currentState))
                                  ]
                                )
                              )
                            ),
                            title: Text(device.type),
                            subtitle: Text(device.manufacturer + " " + device.model),
                            trailing: device.orgUnit != null ? Text(device.orgUnit) : null,
                            onTap: () => {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianDeviceScreen(id: device.id))).then((value) => {
                                if(_filterType == filterMissingManuals) {
                                  _showAllDevices().then((value) => _checkManuals())
                                } else {
                                  _showAllDevices()
                                }
                              })
                            }
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