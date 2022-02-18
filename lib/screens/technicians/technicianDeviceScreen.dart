import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;
import 'package:teog_swift/utilities/deviceInfo.dart';
import 'package:teog_swift/utilities/detailedReport.dart';
import 'package:teog_swift/utilities/deviceState.dart';
import 'package:teog_swift/utilities/messageException.dart';

import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TechnicianDeviceScreen extends StatefulWidget {
  final int id;

  TechnicianDeviceScreen({Key key, @required this.id}) : super(key: key);

  @override
  _TechnicianDeviceScreenState createState() => _TechnicianDeviceScreenState();
}

class _TechnicianDeviceScreenState extends State<TechnicianDeviceScreen> {
  int _userId = -1;
  DeviceInfo _deviceInfo;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Comm.getDeviceInfo(widget.id).then((deviceInfo) {
      _updateDeviceInfo(deviceInfo);
    }).onError<MessageException>((error, stackTrace) {
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    Prefs.getUser().then((userId) => _userId = userId);
  }

  void _updateDeviceInfo(DeviceInfo modifiedDeviceInfo) {
    setState(() {
      this._deviceInfo = modifiedDeviceInfo;
    });
  }

  void _editDevice() {
    //TODO: should those be disposed?
    TextEditingController typeController = TextEditingController(text: this._deviceInfo.device.type);
    TextEditingController manufacturerController = TextEditingController(text: this._deviceInfo.device.manufacturer);
    TextEditingController modelController = TextEditingController(text: this._deviceInfo.device.model);
    int maintenanceInterval = (this._deviceInfo.device.maintenanceInterval/4).ceil();

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: typeController,
                    decoration: new InputDecoration(
                      labelText: 'Type'),
                  ),
                  TextField(
                    controller: manufacturerController,
                    decoration: new InputDecoration(
                      labelText: 'Manufacturer'),
                  ),
                  TextField(
                    controller: modelController,
                    decoration: new InputDecoration(
                      labelText: 'Model'),
                  ),
                  Text("Maintenance interval (months):"),
                  NumberPicker(
                    minValue: 1,
                    maxValue: 24,
                    value: maintenanceInterval,
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
                }),
            ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  String type = typeController.text;
                  String manufacturer = manufacturerController.text;
                  String model = modelController.text;

                  Comm.editDevice(
                    HospitalDevice(id: this._deviceInfo.device.id, type: type, manufacturer: manufacturer, model: model, orgUnitId: this._deviceInfo.device.orgUnitId, orgUnit: this._deviceInfo.device.orgUnit, maintenanceInterval: maintenanceInterval*4)).then((modifiedDeviceInfo) {
                    
                    _updateDeviceInfo(modifiedDeviceInfo);
                  });

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
  }

  void _createReport() async {
    final titleTextController = TextEditingController();
    final descriptionTextController = TextEditingController();
    int selectedState = _deviceInfo.reports[0].currentState;

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text("Create a report"),
          contentPadding: const EdgeInsets.all(16.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: titleTextController,
                    decoration: new InputDecoration(
                      labelText: 'Title'),
                  ),
                  TextField(
                    controller: descriptionTextController,
                    decoration: new InputDecoration(
                      labelText: 'Description'),
                  ),
                  DropdownButton<int>(
                    hint: Text("Current state"),
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
                                SizedBox(width: 5),
                                Text(DeviceState.getStateString(state)),
                              ]
                            )
                          ),
                        );
                      }
                    ).toList(),
                    onChanged: (newValue) => {
                      setState(() {
                        selectedState = newValue;
                      })
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

                  Comm.createReport(_deviceInfo.device.id, title, description, selectedState).then((report) => {
                    setState(() {
                      _deviceInfo.reports.insert(0, report);//TODO: get reports from server
                    })
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
    HospitalDevice device;
    List<DetailedReport> reports;

    if(_deviceInfo != null) {
      device = _deviceInfo.device;
      reports = _deviceInfo.reports;
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(_deviceInfo != null ? device.type : "loading..."),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(padding: EdgeInsets.all(10.0),
            child: (_deviceInfo != null && _userId >= 0) ? Column(
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
                            SelectableText(device.manufacturer + " " + device.model, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            device.orgUnit != null ? Text(device.orgUnit, style: TextStyle(fontSize: 25)) : Text(""),
                            Text("Maintenance interval: " + (device.maintenanceInterval/4).toString() + " months"),
                            TextButton(
                              child: Text('edit'),
                              onPressed: () => _editDevice(),
                            ),
                          ],
                        )
                      )
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("You can scan this code using the mobile app."),
                        QrImage(
                          data: _deviceInfo.device.id.toString(),
                          version: QrVersions.auto,
                          size: 100.0,
                        ),
                      ]
                    )
                  ],
                ),
                Divider(),
                SizedBox(height: 20),
                Flexible(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: Image.memory(base64Decode(_deviceInfo.imageData))),
                    SizedBox(width: 30),
                    Expanded(
                      flex: 2,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StateScreen(deviceInfo: _deviceInfo),
                          Flexible(
                            child: Container(
                              color: Colors.grey[200],
                              child: Scrollbar(isAlwaysShown: true,
                                controller: _scrollController,
                                child: ListView.separated(
                                  controller: _scrollController,
                                  itemCount: reports.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    DetailedReport report = reports[index];
                                    // Flutter does not support date formatting without libraries
                                    String dateStamp = report.created.toString().substring(0, report.created.toString().length-7);

                                    return Padding(
                                      padding: EdgeInsets.all(15.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(dateStamp, textAlign: report.authorId == _userId ? TextAlign.right : TextAlign.left),
                                          Card(
                                            color: report.authorId == _userId ? Color(Constants.teog_blue_lighter) : Colors.white,
                                            child: Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(child: Text(report.authorId == _userId ? "You:" : report.author + ":")),
                                                      Icon(DeviceState.getIconData(report.currentState),
                                                        color: DeviceState.getColor(report.currentState)
                                                      )
                                                    ]
                                                  ),
                                                  Text(report.title, style: TextStyle(fontWeight: FontWeight.bold)),
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
                          SizedBox(height: 10,),
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
                          Text("Available Documents:", style: TextStyle(fontSize: 25)),
                          SizedBox(height: 10),
                          Flexible(child: DocumentScreen(deviceInfo: _deviceInfo)),
                        ],
                      )
                    )
                  ]
                )), 
              ]
            ) : Center(child: CircularProgressIndicator())
          ),
        )
      ))
    );
  }
}

class DocumentScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;

  DocumentScreen({Key key, @required this.deviceInfo}) : super(key: key);

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<String> _documents = [];

  bool _uploading = false;

  void _uploadDocuments() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
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
        if(file.extension == 'pdf') {
          List<String> documents = await Comm.uploadDocument(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model, file.name, file.bytes);

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
    Comm.retrieveDocuments(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model).then((documents) {
      setState(() { _documents = documents; });
    }).onError<MessageException>((error, stackTrace) {
      //ignore
    });
  }

  void _downloadDocument(String docName) {
    String url = Comm.getBaseUrl() + "device_documents/" + widget.deviceInfo.device.manufacturer + "/" + widget.deviceInfo.device.model + "/" + docName;
    html.AnchorElement anchorElement =  new html.AnchorElement(href: url);
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
      uploadWidget = CircularProgressIndicator(value: null);
    } else {
      uploadWidget = ElevatedButton(
        child: Text("upload documents"),
        onPressed: () => _uploadDocuments(),
      );
    }

    return Column(
      children: [
        _documents.length > 0
          ? Flexible(child: Scrollbar(
              isAlwaysShown: true,
              child: ListView.separated(
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
          ))
          : Expanded(child: Center(child: const Text('No documents found'))),
          uploadWidget,
      ]
    );
  }
}

class StateScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;

  StateScreen({Key key, @required this.deviceInfo}) : super(key: key);

  @override
  _StateScreenState createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {

  @override
  Widget build(BuildContext context) {
    List<DetailedReport> reports = widget.deviceInfo.reports;
    DetailedReport latestReport = reports[0];

    return Column(
      children: [
        Container(color: DeviceState.getColor(latestReport.currentState),
          child: Padding(padding: EdgeInsets.all(7.0),
            child: Row(children: [
                Icon(DeviceState.getIconData(latestReport.currentState)),
                SizedBox(width: 5),
                Text(DeviceState.getStateString(latestReport.currentState),
                  style: TextStyle(fontSize: 25)
                ),
                Spacer(),
                Text(DateTime.now().difference(latestReport.created).inDays.toString() + " days",
                  style: TextStyle(fontSize: 25))
              ]
            )
          )
        ),
      ]
    );
  }
}
