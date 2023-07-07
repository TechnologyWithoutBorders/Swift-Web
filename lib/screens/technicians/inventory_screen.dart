import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:teog_swift/screens/organization_filter_view.dart';
import 'package:teog_swift/screens/report_history_plot.dart';
import 'package:teog_swift/screens/technicians/technician_device_screen.dart';
import 'package:teog_swift/utilities/hospital_device.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/message_exception.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _scrollController = ScrollController();
  double _progress = 0;

  List<ShortDeviceInfo> _devices = [];
  List<ShortDeviceInfo> _assignedDevices = [];
  List<ShortDeviceInfo> _preFilteredDevices = [];
  List<ShortDeviceInfo> _displayedDevices = [];

  final _filterTextController = TextEditingController();

  static const int filterNone = -1;

  DepartmentFilter? _departmentFilter;
  int _filterState = filterNone;

  @override
  void initState() {
    super.initState();

    _initDevices();
  }

  Future<void> _initDevices() async {
    List<ShortDeviceInfo> devices = await comm.getDevices();//TODO: catch Exception
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
      _filterState = filterNone;
    });
  }

  Future<void> _showAllDevices() async {
    List<ShortDeviceInfo> prefilteredDevices = [];
    List<ShortDeviceInfo> displayedDevices = [];

    prefilteredDevices.addAll(_assignedDevices);
    displayedDevices.addAll(prefilteredDevices);

    setState(() {
      _filterTextController.clear();
      _filterState = filterNone;
      _preFilteredDevices = prefilteredDevices;
      _displayedDevices = displayedDevices;
    });
  }

  void _checkManuals() async {
    int counter = 0;

    List<ShortDeviceInfo> devices = await comm.getDevices();
    List<ShortDeviceInfo> devicesMissingDocuments = [];

    for(ShortDeviceInfo deviceInfo in devices) {
      try {
        List<String> documents = await comm.retrieveDocuments(deviceInfo.device.manufacturer, deviceInfo.device.model);

        if(documents.isEmpty) {
          devicesMissingDocuments.add(deviceInfo);
        }
      } catch(e) {//TODO: specific exception
        devicesMissingDocuments.add(deviceInfo);
      }

      counter++;

      setState(() {
        _progress = counter/devices.length;
      });
    }

    //TODO: download list
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
        _filterState = filterNone;
      });
    });
  }

  void _filterByState(int state) {
    List<ShortDeviceInfo> preFilteredDevices = [];
    List<ShortDeviceInfo> displayedDevices = [];

    for(ShortDeviceInfo deviceInfo in _devices) {
      if(deviceInfo.report.currentState == state) {
        preFilteredDevices.add(deviceInfo);
        displayedDevices.add(deviceInfo);
      }
    }

    setState(() {
        _preFilteredDevices = preFilteredDevices;
        _displayedDevices = displayedDevices;
        _filterTextController.clear();
        _filterState = state;
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
    List<List<dynamic>> exportList = [["ID", "Type", "Manufacturer", "Model", "Serial Number", "Department", "State"]];

    for(ShortDeviceInfo deviceInfo in _displayedDevices) {
      HospitalDevice device = deviceInfo.device;
      Report report = deviceInfo.report;

      String department = "";

      if(device.orgUnit != null) {
        department = device.orgUnit!;
      }

      exportList.add([device.id, device.type, device.manufacturer, device.model, device.serialNumber, department, DeviceState.getStateString(report.currentState)]);
    }

    String csv = const ListToCsvConverter().convert(exportList, fieldDelimiter: ';');
    final Uint8List data = Uint8List.fromList(csv.codeUnits);

    MimeType type = MimeType.csv;

    await FileSaver.instance.saveFile(
      name: "inventory.csv",
      bytes: data,
      ext: "csv",
      mimeType: type);
  }

  void _plotHistory() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const ReportHistoryPlot();
      }
    );
  }

  void _deleteDevice(ShortDeviceInfo deviceInfo) {
    HospitalDevice device = deviceInfo.device;

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure you want to delete this device?"),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Delete'),
                onPressed: () {
                  comm.deleteDevice(device).then((_) {
                    setState(() {
                    _devices.remove(deviceInfo);
                    _assignedDevices.remove(deviceInfo);
                    _preFilteredDevices.remove(deviceInfo);
                    _displayedDevices.remove(deviceInfo);
                  });
                  }).onError<MessageException>((error, stackTrace) {
                    final snackBar = SnackBar(content: Text(error.message));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  });

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> templateButtons = [
      ElevatedButton(
        onPressed: () => _showAllDevices(),
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(_filterState == filterNone ? const Color(Constants.teogBlue) : Colors.blueGrey)),
        child: const Text("All"),
      ),
    ];

    for(int i = 0; i < DeviceState.names.length; i++) {
      TextButton stateButton = TextButton(
        onPressed: () => _filterByState(i),
        child: Icon(DeviceState.getIconData(i), color: DeviceState.getColor(i)),
      );

      templateButtons.add(stateButton);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      _departmentFilter != null ? Text("Department: ${_departmentFilter!.parent.name}", style: const TextStyle(fontSize: 25)) : Container(),
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
                            _filterState = filterNone;
                          });
                        }, 
                      ): Container(),
                      FilledButton(onPressed: () => _filterDepartment(), child: const Text("select department...")),
                    ]
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: templateButtons,
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child:
                    TextField(
                      controller: _filterTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "filter by searching...",
                      ),
                      onChanged: (text) => _filter(text.trim().toLowerCase()),
                    )
                  ),
                  const SizedBox(height: 15),
                  Text("Number of devices matching filter: ${_displayedDevices.length}", style: const TextStyle(fontSize: 20)),
                  Flexible(child: Padding(padding: const EdgeInsets.all(10.0),
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
                              child: Padding(padding: const EdgeInsets.all(6.0),
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
                            subtitle: Text("${device.manufacturer} ${device.model}"),
                            trailing: ButtonBar(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                device.orgUnit != null ? Text(device.orgUnit!) : const SizedBox.shrink(),
                                TextButton(child: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDevice(deviceInfo))
                              ],
                            ),
                            onTap: () => {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianDeviceScreen(id: device.id))).then((value) => {
                                //TODO: Geräte ohne Handbuch zeigen, falls das vorher ausgewählt war
                              })
                            }
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) => const Divider(),
                      ),
                    ),
                  )),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _csvExportInventory(),
                        child: const Text("Export current list"),
                      ),
                      ElevatedButton(
                        onPressed: () => _plotHistory(),
                        child: const Text("Plot state history"),
                      ),
                      ElevatedButton(
                        onPressed: () => _checkManuals,
                        child: const Text("Get devices with missing documents")
                      ),
                      CircularProgressIndicator(value: _progress)
                    ],
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