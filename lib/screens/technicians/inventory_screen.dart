import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:teog_swift/screens/organization_filter_view.dart';
import 'package:teog_swift/screens/report_history_plot.dart';
import 'package:teog_swift/utilities/hospital_device.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/preference_manager.dart' as prefs;
import 'package:teog_swift/utilities/device_info.dart';
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/detailed_report.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/message_exception.dart';

import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

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

  DeviceInfo? _selectedDeviceInfo;

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

    await FileSaver.instance.saveFile(
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
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(_filterState == filterNone ? const Color(Constants.teogBlue) : Colors.blueGrey)),
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
                            onChanged: (text) => _filter(text),
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
                                  selected: _selectedDeviceInfo != null && _selectedDeviceInfo!.device.id == device.id,
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
                                      Tooltip(message: "delete device", child: TextButton(child: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDevice(deviceInfo)))
                                    ],
                                  ),
                                  onTap: () => {
                                    comm.getDeviceInfo(device.id).then((deviceInfo) {
                                      setState(() {
                                        _selectedDeviceInfo = deviceInfo;
                                      });
                                    }).onError<MessageException>((error, stackTrace) {
                                      final snackBar = SnackBar(content: Text(error.message));
                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                  Expanded(child: _selectedDeviceInfo != null ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(flex: 3, child: _selectedDeviceInfo!.imageData != null && _selectedDeviceInfo!.imageData!.isNotEmpty ? Image.memory(base64Decode(_selectedDeviceInfo!.imageData!)) : const Text("no image available")),
                          Expanded(flex: 2, child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SelectableText("${_selectedDeviceInfo!.device.manufacturer} ${_selectedDeviceInfo!.device.model}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                              _selectedDeviceInfo!.device.orgUnit != null ? Text(_selectedDeviceInfo!.device.orgUnit!, style: const TextStyle(fontSize: 25)) : const Text(""),
                              SelectableText("Serial number: ${_selectedDeviceInfo!.device.serialNumber}"),
                              Text("Maintenance interval: ${_selectedDeviceInfo!.device.maintenanceInterval/4} months"),
                            ]
                          )),
                          Expanded(flex: 1, child: Center(child: QrImageView(
                            data: _selectedDeviceInfo!.device.id.toString(),
                            version: QrVersions.auto,
                            size: 100.0,
                          ))),
                        ]
                      )),
                      const SizedBox(height: 10),
                      Expanded(flex: 2, child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: ReportHistoryScreen(deviceInfo: _selectedDeviceInfo!)),
                          Expanded(child: DocumentScreen(deviceInfo: _selectedDeviceInfo!))
                        ]
                      )),
                    ]
                  ) : const Center())
                ]
              ),
            ),
          )     
        )
      )
    );
  }
}

class ReportHistoryScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;

  const ReportHistoryScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final _scrollController = ScrollController();
  int? _userId;

  @override
  void initState() {
    super.initState();

    prefs.getUser().then((userId) => {
      setState(() {
        _userId = userId;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DetailedReport> reports = widget.deviceInfo.reports;
    DetailedReport latestReport = reports.last;

    return Column(
      children: [
        Container(color: DeviceState.getColor(latestReport.currentState),
          child: Padding(padding: const EdgeInsets.all(7.0),
            child: Row(
              children: [
                Icon(DeviceState.getIconData(latestReport.currentState)),
                const SizedBox(width: 5),
                Text(DeviceState.getStateString(latestReport.currentState),
                  style: const TextStyle(fontSize: 25)
                ),
                const Spacer(),
                Text("${DateTime.now().difference(latestReport.created).inDays} days",
                  style: const TextStyle(fontSize: 25))
              ]
            )
          )
        ),
        Flexible(
          child: Container(
            color: Colors.grey[200],
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.separated(
                controller: _scrollController,
                itemCount: reports.length,
                itemBuilder: (BuildContext context, int index) {
                  DetailedReport report = reports![index];
                  // Flutter does not support date formatting without libraries
                  String dateStamp = report.created.toString().substring(0, report.created.toString().length-7);

                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(dateStamp, textAlign: report.authorId == _userId ? TextAlign.right : TextAlign.left),
                        Card(
                          color: report.authorId == _userId ? const Color(Constants.teogBlueLighter) : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(report.authorId == _userId ? "You:" : "${report.author}:")),
                                    Icon(DeviceState.getIconData(report.currentState),
                                      color: DeviceState.getColor(report.currentState)
                                    )
                                  ]
                                ),
                                Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(report.description)
                              ]
                            )
                          )
                        )
                      ]
                    )
                  );
                },
                separatorBuilder: (BuildContext context, int index) => Container(),
              ),
            ),
          )
        ),
        const SizedBox(height: 10,),
        ElevatedButton(
          child: const Text('Create report'),
          onPressed: () => {}
        ),
      ]
    );
  }
}

class DocumentScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;

  const DocumentScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<String> _documents = [];

  bool _uploading = false;

  final _scrollController = ScrollController();

  void _uploadDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if(result != null) {
      setState(() {
        _uploading = true;
      });

      List<PlatformFile> files = result.files;

      for(PlatformFile file in files) {
        Uint8List? content = file.bytes;

        if(file.extension == 'pdf' && content != null) {
          List<String> documents = await comm.uploadDocument(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model, file.name, content);

          setState(() {
            _documents = documents;
          });
        }
      }
    }

    setState(() {
      _uploading = false;
    });
  }

  void _retrieveDocuments() {
    comm.retrieveDocuments(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model).then((documents) {
      setState(() { _documents = documents; });
    }).onError<MessageException>((error, stackTrace) {
      //ignore
    });
  }

  void _downloadDocument(String docName) {
    String url = "${comm.getBaseUrl()}device_documents/${widget.deviceInfo.device.manufacturer}/${widget.deviceInfo.device.model}/$docName";
    html.AnchorElement anchorElement =  html.AnchorElement(href: url);
    anchorElement.download = url;
    anchorElement.click();
  }

  @override
  void initState() {
    super.initState();

    _retrieveDocuments();
  }

  @override
  Widget build(BuildContext context) {
    Widget uploadWidget;

    if(_uploading) {
      uploadWidget = const CircularProgressIndicator(value: null);
    } else {
      uploadWidget = ElevatedButton(
        child: const Text("upload documents"),
        onPressed: () => _uploadDocuments(),
      );
    }

    return Column(
      children: [
        const Text("Available Documents:", style: TextStyle(fontSize: 25)),
        const SizedBox(height: 10),
        _documents.isNotEmpty ? Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _documents.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Center(child: Text(_documents[index])),
                  onTap: () => _downloadDocument(_documents[index])
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            )
          )
        ) : const Expanded(child: Center(child: Text('No documents found'))),
        uploadWidget,
      ]
    );
  }
}