import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:teog_swift/screens/organizationFilterView.dart';
import 'package:teog_swift/screens/technicians/technicianDeviceScreen.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/shortDeviceInfo.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/deviceState.dart';

class InventoryScreen extends StatefulWidget {
  InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _scrollController = ScrollController();
  double _progress = 0;

  List<ShortDeviceInfo> _devices = [];
  List<ShortDeviceInfo> _assignedDevices = [];
  List<ShortDeviceInfo> _preFilteredDevices = [];
  List<ShortDeviceInfo> _displayedDevices = [];

  final _filterTextController = TextEditingController();

  bool _manualButtonDisabled = false;

  static const int filterNone = 0;
  static const int filterMissingManuals = 1;

  DepartmentFilter? _departmentFilter;
  int _filterType = filterNone;

  @override
  void initState() {
    super.initState();

    _initDevices();
  }

  Future<void> _initDevices() async {
    List<ShortDeviceInfo> devices = await Comm.getDevices();//TODO: catch Exception
    List<ShortDeviceInfo> assignedDevices = [];
    assignedDevices.addAll(devices);
    List<ShortDeviceInfo> prefilteredDevices = [];
    prefilteredDevices.addAll(assignedDevices);
    List<ShortDeviceInfo> displayedDevices = [];
    displayedDevices.addAll(prefilteredDevices);
    
    setState(() {
      _devices = devices;
      _assignedDevices = assignedDevices;
      _preFilteredDevices = prefilteredDevices;
      _displayedDevices = displayedDevices;
      _filterTextController.clear();
      _filterType = filterNone;
    });
  }

  Future<void> _showAllDevices() async {
    List<ShortDeviceInfo> prefilteredDevices = [];
    List<ShortDeviceInfo> displayedDevices = [];

    prefilteredDevices.addAll(_assignedDevices);
    displayedDevices.addAll(prefilteredDevices);

    setState(() {
      _filterTextController.clear();
      _filterType = filterNone;
      _preFilteredDevices = prefilteredDevices;
      _displayedDevices = displayedDevices;
    });
  }

  void _checkManuals() async {
    setState(() {
      _manualButtonDisabled = true;

      _preFilteredDevices.clear();
      _displayedDevices.clear();
      _filterTextController.clear();
      _filterType = filterMissingManuals;
    });

    int counter = 0;

    for(ShortDeviceInfo deviceInfo in _assignedDevices) {
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
        _progress = counter/_assignedDevices.length;
      });
    }

    setState(() {
      _manualButtonDisabled = false;
    });
  }

  void _filterDepartment() {
    showDialog<DepartmentFilter>(
      context: context,
      builder: (BuildContext context) {
        return OrganizationFilterView(orgUnit: _departmentFilter?.parent);
      }
    ).then((departmentFilter) {
      List<ShortDeviceInfo> assignedDevices = [];
      List<ShortDeviceInfo> preFilteredDevices = [];
      List<ShortDeviceInfo> displayedDevices = [];

      if(departmentFilter == null) {
        assignedDevices.addAll(_devices);
        preFilteredDevices.addAll(assignedDevices);
        displayedDevices.addAll(preFilteredDevices);
      } else {
        for(ShortDeviceInfo deviceInfo in _devices) {
          if(departmentFilter.parent.id == deviceInfo.device.orgUnitId || departmentFilter.successors.contains(deviceInfo.device.orgUnitId)) {
            assignedDevices.add(deviceInfo);
            preFilteredDevices.add(deviceInfo);
            displayedDevices.add(deviceInfo);
          }
        }
      }

      setState(() {
        _departmentFilter = departmentFilter;

        _assignedDevices = assignedDevices;
        _preFilteredDevices = preFilteredDevices;
        _displayedDevices = displayedDevices;
        _filterTextController.clear();
        _filterType = filterNone;
      });
    });
  }

  void _filter(String text) {
    setState(() {
      _displayedDevices.clear();
    });

    List<String> filterTexts = text.trim().split(" ");

    for(ShortDeviceInfo deviceInfo in _preFilteredDevices) {
      HospitalDevice device = deviceInfo.device;

      bool skip = false;

      for(String filterText in filterTexts) {
        if(device.type.toLowerCase().contains(filterText) || device.manufacturer.toLowerCase().contains(filterText) || device.model.toLowerCase().contains(filterText) || device.serialNumber.toLowerCase().contains(filterText)) {
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

  void _csvExportInventory() async {
    List<List<dynamic>> exportList = [["Type", "Manufacturer", "Model"]];

    for(ShortDeviceInfo deviceInfo in _displayedDevices) {
      HospitalDevice device = deviceInfo.device;

      exportList.add([device.type, device.manufacturer, device.model]);
    }

    String csv = const ListToCsvConverter().convert(exportList, fieldDelimiter: ';');
    final Uint8List data = Uint8List.fromList(csv.codeUnits);

    MimeType type = MimeType.CSV;

    await FileSaver.instance.saveFile(
      "inventory.csv",
      data,
      "csv",
      mimeType: type);
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
                      _departmentFilter != null ? Text("Department: " + _departmentFilter!.parent.name, style: TextStyle(fontSize: 25)) : Container(),
                      _departmentFilter != null ? IconButton(
                        iconSize: 25,
                        icon: Icon(Icons.cancel_outlined, color: Colors.red[700]),
                        tooltip: "clear selection",
                        onPressed: () {
                          List<ShortDeviceInfo> assignedDevices = [];
                          List<ShortDeviceInfo> preFilteredDevices = [];
                          List<ShortDeviceInfo> displayedDevices = [];

                          assignedDevices.addAll(_devices);
                          preFilteredDevices.addAll(assignedDevices);
                          displayedDevices.addAll(preFilteredDevices);
                          
                          setState(() {
                            _departmentFilter = null;
                            _assignedDevices = assignedDevices;
                            _preFilteredDevices = preFilteredDevices;
                            _displayedDevices = displayedDevices;
                            _filterTextController.clear();
                            _filterType = filterNone;
                          });
                        }, 
                      ): Container(),
                      OutlinedButton(onPressed: () => _filterDepartment(), child: Text("select department...")),
                    ]
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      Text("Select devices by template: ", style: TextStyle(fontSize: 20)),
                      ElevatedButton(
                        child: Text("All"),
                        onPressed: _manualButtonDisabled ? null : () => _showAllDevices(),
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(_filterType == filterNone ? Color(Constants.teog_blue) : Colors.blueGrey))
                      ),
                      ElevatedButton(
                        child: Text("No manual attached"),
                        onPressed: _manualButtonDisabled ? null : () => _checkManuals(),
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(_filterType == filterMissingManuals ? Color(Constants.teog_blue) : Colors.blueGrey))
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _filterTextController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "filter by searching...",
                    ),
                    onChanged: (text) => _filter(text.trim().toLowerCase()),
                    enabled: !_manualButtonDisabled
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _progress
                  ),
                  SizedBox(height: 10),
                  Text("Number of devices matching filter: " + _displayedDevices.length.toString(), style: TextStyle(fontSize: 20)),
                  Flexible(child: Padding(padding: EdgeInsets.all(10.0),
                    child: Scrollbar(
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
                            leading: Container(width: 40, height: 40, color: DeviceState.getColor(report.currentState),
                              child: Padding(padding: EdgeInsets.all(6.0),
                                child: Center(child: (
                                    Icon(DeviceState.getIconData(report.currentState),
                                      size: 28,
                                      color: Colors.grey[900],
                                    )
                                  )
                                )
                              )
                            ),
                            title: Text(device.type),
                            subtitle: Text(device.manufacturer + " " + device.model),
                            trailing: device.orgUnit != null ? Text(device.orgUnit!) : null,
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
                  ElevatedButton(
                    child: Text("Export list"),
                    onPressed: () => _csvExportInventory()
                  ),
                ]
              ),
            ),
          )     
        )
      )
    );
  }
}