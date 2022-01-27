import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
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
  DeviceInfo _deviceInfo;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Comm.getDeviceInfo(widget.id).then((deviceInfo) {
      _updateDeviceInfo(deviceInfo);
    }).onError<MessageException>((error, stackTrace) {
      print(error.message);
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
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
    TextEditingController locationController = TextEditingController(text: this._deviceInfo.device.location);

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Column(
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
              TextField(
                controller: locationController,
                decoration: new InputDecoration(
                  labelText: 'Location'),
              ),
            ],
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
                  String location = locationController.text;

                  Comm.editDevice(
                    HospitalDevice(id: this._deviceInfo.device.id, type: type, manufacturer: manufacturer, model: model, location: location)).then((modifiedDeviceInfo) {
                    
                    _updateDeviceInfo(modifiedDeviceInfo);
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
    HospitalDevice device = _deviceInfo.device;
    List<DetailedReport> reports = _deviceInfo.reports;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(device.type),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(padding: EdgeInsets.all(10.0),
            child: Column(
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
                            SelectableText(device.location, style: TextStyle(fontSize: 25)),
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
                SizedBox(height: 50),
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
                            child: Scrollbar(isAlwaysShown: true,
                              controller: _scrollController,
                              child: ListView.separated(
                                controller: _scrollController,
                                itemCount: reports.length,
                                itemBuilder: (BuildContext context, int index) {
                                  DetailedReport report = reports[index];

                                  return ListTile(
                                    title: Text(report.title),
                                    subtitle: Text(report.description),
                                  );
                                },
                                separatorBuilder: (BuildContext context, int index) => const Divider(),
                              ),
                            ),
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
            )
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
    );

    if(result != null) {
      setState(() {
        _uploading = true;
      });

      List<PlatformFile> files = result.files;

      for(PlatformFile file in files) {
        //TODO: check pdf extension

        List<String> documents = await Comm.uploadDocument(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model, file.name, file.bytes);

        setState(() {
          _documents = documents;
        });
      }
    }

    setState(() {
      _uploading = false;
    });
  }

  void _retrieveDocuments() {
    Comm.retrieveDocuments(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model).then((documents) {//TODO catch Exception
      setState(() { _documents = documents; });
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
        child: Text("add"),
        onPressed: () => _uploadDocuments(),
      );
    }

    return Column(
      children: [
        uploadWidget,
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
          : Center(child: const Text('No documents found')),
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
    DetailedReport lastReport = reports[reports.length-1];

    return Column(
      children: [
        Text("Current State:", style: TextStyle(fontSize: 25)),
        SizedBox(height: 10),
          Container(color: DeviceState.getColor(lastReport.currentState),
          child: Padding(padding: EdgeInsets.all(3.0),
            child: Row(children: [
                Icon(DeviceState.getIconData(lastReport.currentState)),
              SizedBox(width: 5),
              Text(DeviceState.getStateString(lastReport.currentState),
                style: TextStyle(fontSize: 25)
              ),
              ]
            )
          )
        ),
        SizedBox(height: 5),
        Text(DateTime.now().difference(lastReport.created).inDays.toString() + " days"),
      ]
    );
  }
}

class ReportProblemForm extends StatefulWidget {
  final DeviceInfo deviceInfo;

  final ValueChanged<DeviceInfo> updateDeviceInfo;

  ReportProblemForm({Key key, @required this.deviceInfo, this.updateDeviceInfo}) : super(key: key);

  @override
  _ReportProblemFormState createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends State<ReportProblemForm> {
  final _formKey = GlobalKey<FormState>();

  final _reportTitleController = TextEditingController();
  final _problemTextController = TextEditingController();

  void _createReport() {
    if (_formKey.currentState.validate()) {
      Comm.queueRepair(479, _reportTitleController.text, _problemTextController.text).then((newReport) {
        //widget.updateDeviceInfo(DeviceInfo(device: widget.deviceInfo.device, report: newReport, imageData: widget.deviceInfo.imageData));
      }).onError((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(width: 400,
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent)
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            Text("Report a problem", style: Theme
                .of(context)
                .textTheme
                .headline5),
            TextFormField(
              controller: _reportTitleController,
              decoration: InputDecoration(hintText: "Title"),
              validator: (value) {
                if (value.isEmpty) {
                  return "Please give your report a title.";
                }
                return null;
              },
              onFieldSubmitted: (value) => _createReport(),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _problemTextController,
                decoration: InputDecoration(hintText: "Problem description"),
                maxLines: 4,
                validator: (value) {
                  if (value.isEmpty) {
                    return "Please describe the problem in a few sentences.";
                  }
                  return null;
                },
                onFieldSubmitted: (value) => _createReport(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _createReport();
                }
              },
              child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 8.0), child: Text('Request repair')),
            ),
          ],
        ),
      ),
    );
  }
}
