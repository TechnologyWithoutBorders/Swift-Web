import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/hospital_device.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/preference_manager.dart' as prefs;
import 'package:teog_swift/utilities/device_info.dart';
import 'package:teog_swift/utilities/detailed_report.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/message_exception.dart';

import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TechnicianDeviceScreen extends StatefulWidget {
  final int id;

  const TechnicianDeviceScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<TechnicianDeviceScreen> createState() => _TechnicianDeviceScreenState();
}

class _TechnicianDeviceScreenState extends State<TechnicianDeviceScreen> {
  int? _userId;
  DeviceInfo? _deviceInfo;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    comm.getDeviceInfo(widget.id).then((deviceInfo) {
      _updateDeviceInfo(deviceInfo);
    }).onError<MessageException>((error, stackTrace) {
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    prefs.getUser().then((userId) => {
      setState(() {
        _userId = userId;
      })
    });
  }

  void _updateDeviceInfo(DeviceInfo modifiedDeviceInfo) {
    setState(() {
      _deviceInfo = modifiedDeviceInfo;
    });
  }

  void _editDevice() {
    HospitalDevice? device = _deviceInfo?.device;

    if(device != null) {
      TextEditingController typeController = TextEditingController(text: device.type);
      TextEditingController manufacturerController = TextEditingController(text: device.manufacturer);
      TextEditingController modelController = TextEditingController(text: device.model);
      int maintenanceInterval = (device.maintenanceInterval/4).ceil();

      showDialog<String>(
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
                      
                      _updateDeviceInfo(modifiedDeviceInfo);
                    });

                    Navigator.pop(context);

                    typeController.dispose();
                    manufacturerController.dispose();
                    modelController.dispose();
                  })
            ],
          );
        }
      );
    }
  }

  void _createReport() async {
    HospitalDevice? device = _deviceInfo?.device;
    List<DetailedReport>? reports = _deviceInfo?.reports;

    if(device != null && reports != null) {
      final titleTextController = TextEditingController();
      final descriptionTextController = TextEditingController();
      int selectedState = reports[0].currentState;

      await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Create a report"),
            contentPadding: const EdgeInsets.all(16.0),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: titleTextController,
                      decoration: const InputDecoration(
                        labelText: 'Title'),
                      maxLength: 25,
                    ),
                    TextField(
                      controller: descriptionTextController,
                      decoration: const InputDecoration(
                        labelText: 'Description'),
                      maxLength: 600,
                      maxLines: null,
                    ),
                    DropdownButton<int>(
                      hint: const Text("Current state"),
                      value: selectedState,
                      items: <int>[0, 1, 2, 3, 4, 5]//TODO: das sollte aus DeviceStates kommen
                        .map<DropdownMenuItem<int>>((int state) {
                          return DropdownMenuItem<int>(
                            value: state,
                            child: Container(
                              color: DeviceState.getColor(state),
                              child: Row(
                                children: [
                                  Icon(DeviceState.getIconData(state)),
                                  const SizedBox(width: 5),
                                  Text(DeviceState.getStateString(state)),
                                ]
                              )
                            ),
                          );
                        }
                      ).toList(),
                      onChanged: (newValue) => {
                        if(newValue != null) {
                          setState(() {
                            selectedState = newValue;
                          })
                        }
                      },
                    ),
                  ],
                );
              }
            ),
            actions: <Widget>[
              ElevatedButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    String title = titleTextController.text;
                    String description = descriptionTextController.text;

                    comm.createReport(device.id, title, description, selectedState).then((report) => {
                      setState(() {
                        reports.add(report);//TODO: get reports from server
                      })
                    });

                    Navigator.pop(context);
                  })
            ],
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    HospitalDevice? device;
    List<DetailedReport>? reports;

    if(_deviceInfo != null) {
      device = _deviceInfo!.device;
      reports = _deviceInfo!.reports;
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(device != null ? device.type : "loading..."),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(padding: const EdgeInsets.all(10.0),
            child: (_deviceInfo != null && device != null && reports != null && _userId != null) ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 300.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SelectableText("${device.manufacturer} ${device.model}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            device.orgUnit != null ? Text(device.orgUnit!, style: const TextStyle(fontSize: 25)) : const Text(""),
                            SelectableText("Serial number: ${device.serialNumber}"),
                            Text("Maintenance interval: ${device.maintenanceInterval/4} months"),
                            TextButton(
                              child: const Text('edit'),
                              onPressed: () => _editDevice(),
                            ),
                          ],
                        )
                      )
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("You can scan this code using the mobile app."),
                        QrImageView(
                          data: device.id.toString(),
                          version: QrVersions.auto,
                          size: 100.0,
                        ),
                      ]
                    )
                  ],
                ),
                const Divider(),
                const SizedBox(height: 20),
                Flexible(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _deviceInfo!.imageData != null && _deviceInfo!.imageData!.isNotEmpty ? Image.memory(base64Decode(_deviceInfo!.imageData!)) : const Text("no image available")
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      flex: 2,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StateScreen(deviceInfo: _deviceInfo!),
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
                            onPressed: () => _createReport()
                          ),
                        ]
                      )
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Available Documents:", style: TextStyle(fontSize: 25)),
                          const SizedBox(height: 10),
                          Flexible(child: DocumentScreen(deviceInfo: _deviceInfo!)),
                        ],
                      )
                    )
                  ]
                )), 
              ]
            ) : const Center(child: CircularProgressIndicator())
          ),
        )
      ))
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
        _documents.isNotEmpty ? Flexible(
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

class StateScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;

  const StateScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  State<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {

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
      ]
    );
  }
}
