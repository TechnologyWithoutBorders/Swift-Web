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
import 'package:teog_swift/utilities/device_info.dart';
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/message_exception.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:screenshot/screenshot.dart';

class InventoryScreen extends StatefulWidget {
  final User user;

  const InventoryScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _scrollController = ScrollController();
  int _totalDevices = -1;
  int _checkedDevices = 0;

  List<ShortDeviceInfo> _devices = [];
  List<ShortDeviceInfo> _assignedDevices = [];
  List<ShortDeviceInfo> _preFilteredDevices = [];
  List<ShortDeviceInfo> _displayedDevices = [];

  final _filterTextController = TextEditingController();

  static const int filterNone = -1;

  DepartmentFilter? _departmentFilter;
  int _filterState = filterNone;

  int? _selectedDeviceId;

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
    setState(() {
      _totalDevices = 0;
    });

    List<ShortDeviceInfo> devices = await comm.getDevices();

    setState(() {
      _totalDevices = devices.length;
    });

    List<ShortDeviceInfo> devicesMissingDocuments = [];
    List<String> alreadyChecked = [];

    int counter = 0;

    for(ShortDeviceInfo deviceInfo in devices) {
      HospitalDevice device = deviceInfo.device;

      if(!alreadyChecked.contains("${device.manufacturer.toLowerCase()} ${device.model.toLowerCase()}")) {
        try {
          List<String> documents = await comm.retrieveDocuments(device.manufacturer, device.model);

          if(documents.isEmpty) {
            devicesMissingDocuments.add(deviceInfo);
          }
        } catch(e) {
          devicesMissingDocuments.add(deviceInfo);
        }

        alreadyChecked.add("${device.manufacturer.toLowerCase()} ${device.model.toLowerCase()}");
      }

      counter++;

      setState(() {
        _checkedDevices = counter;
      });
    }

    setState(() {
      _totalDevices = -1;
    });

    List<List<dynamic>> headerList = [["Manufacturer", "Type", "Model"]];
    List<List<dynamic>> exportList = [];

    for(ShortDeviceInfo deviceInfo in devicesMissingDocuments) {
      HospitalDevice device = deviceInfo.device;

      exportList.add([device.manufacturer, device.type, device.model]);
    }

    exportList.sort((a, b) => a.join(' ').compareTo(b.join(' ')));

    headerList.addAll(exportList);

    String csv = const ListToCsvConverter().convert(headerList, fieldDelimiter: ';');
    final Uint8List data = Uint8List.fromList(csv.codeUnits);

    MimeType type = MimeType.csv;

    await FileSaver.instance.saveFile(
      name: "devices_with_missing_documents",
      bytes: data,
      ext: "csv",
      mimeType: type);
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

    if(text.isNotEmpty) {
      List<String> filterTexts = text.trim().toLowerCase().split(" ");

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
    } else {
      setState(() {
        _displayedDevices.addAll(_preFilteredDevices);
      });
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

    FileSaver.instance.saveFile(
      name: "inventory",
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

  void _showBarcode(ShortDeviceInfo deviceInfo) async {
    ScreenshotController screenshotController = ScreenshotController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Barcode'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: Screenshot(
              controller: screenshotController,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Text(deviceInfo.device.type),
                    QrImageView(
                      data: deviceInfo.device.id.toString(),
                      version: QrVersions.auto,
                      size: 150.0
                    ),
                    Text(deviceInfo.device.id.toString())
                  ]
                )
              )
            )
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () async {
                screenshotController.capture().then((data) {
                  MimeType type = MimeType.png;

                  FileSaver.instance.saveFile(
                    name: "barcode_${deviceInfo.device.type.replaceAll(" ", "_")}_${deviceInfo.device.id}",
                    bytes: data,
                    ext: "png",
                    mimeType: type);
                  }
                );
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<DeviceInfo?> _editDevice(ShortDeviceInfo deviceInfo) {
    HospitalDevice device = deviceInfo.device;

    TextEditingController typeController = TextEditingController(text: device.type);
    TextEditingController manufacturerController = TextEditingController(text: device.manufacturer);
    TextEditingController modelController = TextEditingController(text: device.model);
    int maintenanceInterval = (device.maintenanceInterval/4).ceil();

    return showDialog<DeviceInfo?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type'),
                  ),
                  TextField(
                    controller: manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer'),
                  ),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model'),
                  ),
                  const SizedBox(height: 10),
                  const Text("Maintenance interval (months):"),
                  NumberPicker(
                    minValue: 1,
                    maxValue: 24,
                    value: maintenanceInterval,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black26),
                    ),
                    onChanged: (value) => {
                      setState(() {
                        maintenanceInterval = value;
                      })
                    }
                  )
                ],
              );
            }
          ),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);

                  typeController.dispose();
                  manufacturerController.dispose();
                  modelController.dispose();
                }),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                String type = typeController.text;
                String manufacturer = manufacturerController.text;
                String model = modelController.text;

                comm.editDevice(
                  HospitalDevice(id: device.id, type: type, manufacturer: manufacturer, model: model, serialNumber: "", orgUnitId: device.orgUnitId, orgUnit: device.orgUnit, maintenanceInterval: maintenanceInterval*4)).then((modifiedDeviceInfo) {

                  Navigator.pop(context, modifiedDeviceInfo);

                  typeController.dispose();
                  manufacturerController.dispose();
                  modelController.dispose();
                });
              }
            )
          ],
        );
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
      Tooltip(
        message: "show all devices",
        child: ElevatedButton(
          onPressed: () => _showAllDevices(),
          style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(_filterState == filterNone ? const Color(Constants.teogBlue) : Colors.blueGrey)),
          child: const Text("All"),
        )
      ),
    ];

    for(int i = 0; i < DeviceState.names.length; i++) {
      Tooltip stateButton = Tooltip(
        message: DeviceState.getStateString(i),
        child: OutlinedButton(
          onPressed: () => _filterByState(i),
          style: _filterState == i ? OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(Constants.teogBlue)),
          ) : OutlinedButton.styleFrom(),
          child: Icon(DeviceState.getIconData(i), color: DeviceState.getColor(i)),
        )
      );

      templateButtons.add(stateButton);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.95, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: const EdgeInsets.all(25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
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
                            FilledButton(onPressed: () => _filterDepartment(), child: const Text("Select department...")),
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
                              labelText: "Filter by searching...",
                            ),
                            onChanged: (text) => _filter(text),
                          )
                        ),
                        const SizedBox(height: 15),
                        Text("${_displayedDevices.length} devices match the filter.", style: const TextStyle(fontSize: 20)),
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
                                  selected: _selectedDeviceId != null && _selectedDeviceId == device.id,
                                  selectedColor: Colors.black,
                                  selectedTileColor: const Color(Constants.teogBlueLighter),
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
                                      Tooltip(message: "show/download barcode", child: TextButton(child: const Icon(Icons.qr_code), onPressed: () => _showBarcode(deviceInfo))),
                                      Tooltip(message: "edit device", child: TextButton(child: const Icon(Icons.edit), onPressed: () => _editDevice(deviceInfo).then((modifiedDeviceInfo) {
                                        if(modifiedDeviceInfo != null) {
                                          ShortDeviceInfo modifiedDevice = ShortDeviceInfo(device: modifiedDeviceInfo.device, report: deviceInfo.report, imageData: deviceInfo.imageData);

                                          final devicesIndex = _devices.indexWhere((deviceInfo) => deviceInfo.device.id == modifiedDevice.device.id);
                                          final assignedDevicesIndex = _assignedDevices.indexWhere((deviceInfo) => deviceInfo.device.id == modifiedDevice.device.id);
                                          final prefilteredDevicesIndex = _preFilteredDevices.indexWhere((deviceInfo) => deviceInfo.device.id == modifiedDevice.device.id);
                                          final displayedDevicesIndex = _displayedDevices.indexWhere((deviceInfo) => deviceInfo.device.id == modifiedDevice.device.id);

                                          setState(() {
                                            if(devicesIndex >= 0) _devices[devicesIndex] = modifiedDevice;
                                            if(assignedDevicesIndex >= 0) _assignedDevices[assignedDevicesIndex] = modifiedDevice;
                                            if(prefilteredDevicesIndex >= 0) _preFilteredDevices[prefilteredDevicesIndex] = modifiedDevice;
                                            if(displayedDevicesIndex >= 0) _displayedDevices[displayedDevicesIndex] = modifiedDevice;
                                          });
                                        }
                                      }))),
                                      Tooltip(message: "delete device", child: TextButton(child: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDevice(deviceInfo)))
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedDeviceId = device.id;
                                    });
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
                              child: const Text("Plot history"),
                            ),
                            _totalDevices >= 0 ? Text("checking devices for missing documents... $_checkedDevices/$_totalDevices")
                            : ElevatedButton(
                              onPressed: () => _checkManuals(),
                              child: const Text("Get devices with missing documents")
                            ),
                          ],
                        ),
                      ]
                    )
                  ),
                  Expanded(child: _selectedDeviceId != null ? TechnicianDeviceScreen(user: widget.user, deviceId: _selectedDeviceId!) : const Center())
                ]
              ),
            ),
          )     
        )
      )
    );
  }
}