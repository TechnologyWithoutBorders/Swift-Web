import 'dart:convert';
import 'dart:html' as html;
import 'package:teog_swift/main.dart';

import 'package:flutter/material.dart';

import 'networkFunctions.dart' as Comm;
import 'preferenceManager.dart' as Prefs;
import 'deviceInfo.dart';
import 'report.dart';
import 'package:teog_swift/deviceState.dart';

class DetailScreen extends StatefulWidget {
  //this one is never modified
  final DeviceInfo deviceInfo;

  DetailScreen({Key key, @required this.deviceInfo}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState(deviceInfo: deviceInfo);
}

class _DetailScreenState extends State<DetailScreen> {
  DeviceInfo deviceInfo;

  _DetailScreenState({this.deviceInfo});

  _updateDeviceInfo(DeviceInfo modifiedDeviceInfo) {
    setState(() {
      this.deviceInfo = modifiedDeviceInfo;
    });
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
        title: Text(widget.deviceInfo.device.type),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.8, heightFactor: 0.8,
        child: Card(
          child: Padding(padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(deviceInfo.device.manufacturer + " " + deviceInfo.device.model, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                Text(deviceInfo.device.location, style: TextStyle(fontSize: 25)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 350,
                      child: Image.memory(base64Decode(deviceInfo.imageData)),
                    ),
                    SizedBox(width: 30),
                    Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      SizedBox(height: 5),
                      StateScreen(deviceInfo: deviceInfo),
                      SizedBox(height: 20),
                      reportWidget,
                    ])
                  ]
                ),
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

    Prefs.checkLogin().then((success) {
      if(!success) {
        Navigator.of(context).pushNamed(SwiftApp.route);
      } else {
        _retrieveDocuments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 100, width: 300,
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
      : Center(child: const Text('No documents found')),
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
        Text(report.created),
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
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Colors.white;
                }),
                backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Colors.blue;
                }),
              ),
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
