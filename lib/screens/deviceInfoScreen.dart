import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/shortDeviceInfo.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/deviceState.dart';

class DetailScreen extends StatefulWidget {
  //this one is never modified
  final ShortDeviceInfo deviceInfo;

  DetailScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState(deviceInfo: deviceInfo);
}

class _DetailScreenState extends State<DetailScreen> {
  ShortDeviceInfo deviceInfo;

  _DetailScreenState({required this.deviceInfo});

  _updateDeviceInfo(ShortDeviceInfo modifiedDeviceInfo) {
    setState(() {
      this.deviceInfo = modifiedDeviceInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget reportWidget;

    String? reasonText;

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
      body: Center(child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(deviceInfo.device.manufacturer + " " + deviceInfo.device.model, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                deviceInfo.device.orgUnit != null ? Text(deviceInfo.device.orgUnit!, style: TextStyle(fontSize: 25)) : Text(""),
                Divider(),
                SizedBox(height: 20),
                Flexible(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: deviceInfo.imageData != null && deviceInfo.imageData!.isNotEmpty ? Image.memory(base64Decode(deviceInfo.imageData!)) : Text("no image available"),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      flex: 2,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 5),
                          StateScreen(deviceInfo: deviceInfo),
                          SizedBox(height: 20),
                          reportWidget,
                        ]
                      )
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Available Documents:", style: TextStyle(fontSize: 25)),
                          SizedBox(height: 10),
                          Flexible(child: DocumentScreen(deviceInfo: deviceInfo)),
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
  final ShortDeviceInfo deviceInfo;

  DocumentScreen({Key? key, required this.deviceInfo}) : super(key: key);

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
    return Column(
      children: [
        _documents.length > 0 ? Flexible(
          child: Scrollbar(
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
        ) : Expanded(child: Center(child: const Text('No documents found'))),
      ]
    );
  }
}

class StateScreen extends StatefulWidget {
  final ShortDeviceInfo deviceInfo;

  StateScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  _StateScreenState createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {

  @override
  Widget build(BuildContext context) {
    Report report = widget.deviceInfo.report;

    return Column(
      children: [
        Container(color: DeviceState.getColor(report.currentState),
          child: Padding(padding: EdgeInsets.all(7.0),
            child: Row(children: [
                Icon(DeviceState.getIconData(report.currentState)),
                SizedBox(width: 5),
                Text(DeviceState.getStateString(report.currentState),
                  style: TextStyle(fontSize: 25)
                ),
                Spacer(),
                Text(DateTime.now().difference(report.created).inDays.toString() + " days",
                  style: TextStyle(fontSize: 25))
              ]
            )
          )
        ),
      ]
    );
  }
}

class ReportProblemForm extends StatefulWidget {
  final ShortDeviceInfo deviceInfo;

  final ValueChanged<ShortDeviceInfo> updateDeviceInfo;

  ReportProblemForm({Key? key, required this.deviceInfo, required this.updateDeviceInfo}) : super(key: key);

  @override
  _ReportProblemFormState createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends State<ReportProblemForm> {
  final _formKey = GlobalKey<FormState>();

  final _reportTitleController = TextEditingController();
  final _problemTextController = TextEditingController();

  Future<bool> _createReport() async {
    if(_formKey.currentState!.validate()) {
      await Comm.queueRepair(widget.deviceInfo.device.id, _reportTitleController.text, _problemTextController.text).then((newReport) {
        widget.updateDeviceInfo(ShortDeviceInfo(device: widget.deviceInfo.device, report: newReport, imageData: widget.deviceInfo.imageData));
      }).onError((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });

      return true;
    } else {
      return false;
    }
  }

  void _createReportDialog(){
    showDialog<String>(
        context: context,
        builder: (BuildContext context){
          return Form(key: _formKey,
              child: AlertDialog(
                contentPadding: const EdgeInsets.all(16.0),
                content: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("Report a problem", style: Theme
                        .of(context)
                        .textTheme
                        .headline5),
                    TextFormField(
                      controller: _reportTitleController,
                      decoration: new InputDecoration(labelText: 'Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
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
                        decoration: new InputDecoration(labelText: 'Problem description'),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please describe the problem in a few sentences.";
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) => _createReport(),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  ElevatedButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      }
                  ),
                  ElevatedButton(
                    child: Text('Request repair'),
                    onPressed: () async {
                      bool success = await _createReport();
                      
                      if(success) {
                        Navigator.pop(context);
                      }
                    },
                  )
                ],
              )
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return  ElevatedButton(
      onPressed: () => _createReportDialog(),
      child: Text('Report a problem'),
    );
  }
}
