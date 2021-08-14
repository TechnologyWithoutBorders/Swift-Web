import 'dart:convert';
import 'dart:html' as html;
import 'package:teog_swift/main.dart';

import 'package:flutter/material.dart';

import 'networkFunctions.dart' as Comm;
import 'preference_manager.dart' as Prefs;
import 'deviceInfo.dart';
import 'deviceStates.dart' as DeviceState;

class DetailScreen extends StatelessWidget {
  // Declare a field that holds the Todo.
  final DeviceInfo deviceInfo;

  // In the constructor, require a Todo.
  DetailScreen({Key key, @required this.deviceInfo}) : super(key: key);

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
      reportWidget = ReportProblemForm();
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(deviceInfo.device.type),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.65, heightFactor: 0.8,
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
  _DocumentScreenState createState() => _DocumentScreenState(deviceInfo: deviceInfo);
}

class _DocumentScreenState extends State<DocumentScreen> {
  final DeviceInfo deviceInfo;

  List<String> _documents = [];

  _DocumentScreenState({this.deviceInfo});

  void _retrieveDocuments() {
    Comm.retrieveDocuments(deviceInfo.device.manufacturer, deviceInfo.device.model).then((documents) {//TODO catch Exception
      setState(() { _documents = documents; });
    });
  }

  void _downloadDocument(String docName) {
    String url = "https://teog.virlep.de/interface/3/device_documents/" + deviceInfo.device.manufacturer + "/" + deviceInfo.device.model + "/" + docName;
    html.AnchorElement anchorElement =  new html.AnchorElement(href: url);
    anchorElement.download = url;
    anchorElement.click();
  }

  @override
  void initState() {
    super.initState();

    Prefs.checkLogin().then((success) {
      if(!success) {
        Navigator.of(context).pushNamed(SignUpApp.route);
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
  _StateScreenState createState() => _StateScreenState(deviceInfo: deviceInfo);
}

class _StateScreenState extends State<StateScreen> {
  final DeviceInfo deviceInfo;

  _StateScreenState({this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Current state:", style: Theme
          .of(context)
          .textTheme
          .headline5),
        SizedBox(height: 5),
          Container(color: deviceInfo.report.getColor(),
          child: Padding(padding: EdgeInsets.all(3.0),
            child: Row(children: [
                Icon(deviceInfo.report.getIconData()),
              SizedBox(width: 5),
              Text(deviceInfo.report.getStateString(),
                style: TextStyle(fontSize: 25)
              ),
              ]
            )
          )
        ),
        SizedBox(height: 5),
        Text(deviceInfo.report.created),
      ]
    );
  }
}

class ReportProblemForm extends StatefulWidget {
  @override
  _ReportProblemFormState createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends State<ReportProblemForm> {
  final _formKey = GlobalKey<FormState>();

  final _problemTextController = TextEditingController();

  void _createReport() {
    if (_formKey.currentState.validate()) {
      Comm.queueRepair(_problemTextController.text).then((modifiedDeviceInfo) {
        //TODO Gerätedaten aktualisieren
        //setState(() { deviceInfo = modifiedDeviceInfo; });
      }).onError((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
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
            Text('Report a problem', style: Theme
                .of(context)
                .textTheme
                .headline5),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _problemTextController,
                decoration: InputDecoration(hintText: 'Please describe the problem... (not working yet)'),
                maxLines: 4,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
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
                  //Comm.queueRepair("password").then((success) {//TODO Exceptions
                  //  if(success) {
                      //TODO
                  //  }
                  //});
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
