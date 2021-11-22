import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/deviceInfo.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/deviceState.dart';

import 'package:teog_swift/utilities/constants.dart';

import 'package:file_picker/file_picker.dart';

class TechnicianDeviceScreen extends StatefulWidget {
  //this one is never modified
  final DeviceInfo deviceInfo;

  TechnicianDeviceScreen({Key key, @required this.deviceInfo}) : super(key: key);

  @override
  _TechnicianDeviceScreenState createState() => _TechnicianDeviceScreenState(deviceInfo: deviceInfo);
}

class _TechnicianDeviceScreenState extends State<TechnicianDeviceScreen> {
  DeviceInfo deviceInfo;

  _TechnicianDeviceScreenState({this.deviceInfo});

  void _updateDeviceInfo(DeviceInfo modifiedDeviceInfo) {
    setState(() {
      this.deviceInfo = modifiedDeviceInfo;
    });
  }

  void _editDevice() {
    TextEditingController typeController = TextEditingController(text: this.deviceInfo.device.type);
    TextEditingController manufacturerController = TextEditingController(text: this.deviceInfo.device.manufacturer);
    TextEditingController modelController = TextEditingController(text: this.deviceInfo.device.model);
    TextEditingController locationController = TextEditingController(text: this.deviceInfo.device.location);

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: typeController,
                decoration: new InputDecoration(
                  labelText: 'Type'),
              ),
              new TextField(
                controller: manufacturerController,
                decoration: new InputDecoration(
                  labelText: 'Manufacturer'),
              ),
              new TextField(
                controller: modelController,
                decoration: new InputDecoration(
                  labelText: 'Model'),
              ),
              new TextField(
                controller: locationController,
                decoration: new InputDecoration(
                  labelText: 'Location'),
              ),
            ],
          ),
          actions: <Widget>[
            new ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  typeController.dispose();
                  manufacturerController.dispose();
                  modelController.dispose();
                  locationController.dispose();

                  Navigator.pop(context);
                }),
            new ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  Comm.editDevice(
                    HospitalDevice(id: this.deviceInfo.device.id, type: typeController.text, manufacturer: manufacturerController.text, model: modelController.text, location: locationController.text)).then((modifiedDeviceInfo) {
                    
                    _updateDeviceInfo(modifiedDeviceInfo);
                    typeController.dispose();
                    manufacturerController.dispose();
                    modelController.dispose();
                    locationController.dispose();
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
    Widget reportWidget;

    String reasonText;

    switch(deviceInfo.report.currentState) {
      case DeviceState.broken:
        reasonText = "The defect has already been reported.";
        break;
      case DeviceState.inProgress:
        reasonText = "A technician is already working on this device.";
        break;
      case DeviceState.salvage:
        reasonText = "This device cannot be repaired.";
        break;
    }

    if(reasonText != null) {
      reportWidget = Text(reasonText, style: TextStyle(fontSize: 20));
    } else {
      reportWidget = ReportProblemForm(deviceInfo: deviceInfo, updateDeviceInfo: _updateDeviceInfo,);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(deviceInfo.device.type),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(deviceInfo.device.manufacturer + " " + deviceInfo.device.model, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                Text(deviceInfo.device.location, style: TextStyle(fontSize: 25)),
                TextButton(
                  child: Text('edit'),
                  onPressed: () => _editDevice(),
                ),
                SizedBox(height: 20),
                Flexible(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: Image.memory(base64Decode(deviceInfo.imageData))),
                    SizedBox(width: 30),
                    Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      SizedBox(height: 5),
                      StateScreen(deviceInfo: deviceInfo),
                      SizedBox(height: 20),
                      reportWidget,
                    ])
                  ]
                )),
                SizedBox(height: 20),
                Text("Available Documents:", style: TextStyle(fontSize: 20)),
                DocumentScreen(deviceInfo: deviceInfo),
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
    String url = Comm.getBaseUrl() + "/device_documents/" + widget.deviceInfo.device.manufacturer + "/" + widget.deviceInfo.device.model + "/" + docName;
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
      SizedBox(height: 100, width: 300,
      child: _documents.length > 0
        ? Scrollbar(
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
        )
        : Center(child: const Text('No documents found'))),
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
    Report report = widget.deviceInfo.report;

    return Column(
      children: [
        Text("Current state:", style: Theme
          .of(context)
          .textTheme
          .headline5),
        SizedBox(height: 5),
          Container(color: DeviceState.getColor(report.currentState),
          child: Padding(padding: EdgeInsets.all(3.0),
            child: Row(children: [
                Icon(DeviceState.getIconData(report.currentState)),
              SizedBox(width: 5),
              Text(DeviceState.getStateString(report.currentState),
                style: TextStyle(fontSize: 25)
              ),
              ]
            )
          )
        ),
        SizedBox(height: 5),
        Text(DateTime.now().difference(report.created).inDays.toString() + " days"),
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
        widget.updateDeviceInfo(DeviceInfo(device: widget.deviceInfo.device, report: newReport, imageData: widget.deviceInfo.imageData));
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
