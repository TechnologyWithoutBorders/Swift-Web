import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/message_exception.dart';

class DetailScreen extends StatefulWidget {
  //this one is never modified
  final ShortDeviceInfo deviceInfo;

  const DetailScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState(deviceInfo: deviceInfo);
}

class _DetailScreenState extends State<DetailScreen> {
  ShortDeviceInfo deviceInfo;

  _DetailScreenState({required this.deviceInfo});

  _updateDeviceInfo(ShortDeviceInfo modifiedDeviceInfo) {
    setState(() {
      deviceInfo = modifiedDeviceInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget reportWidget;

    String? reasonText;

    switch(deviceInfo.report.currentState) {
      case DeviceState.broken:
        reasonText = "A defect has been reported.";
        break;
      case DeviceState.inProgress:
        reasonText = "A technician is already working on this device.";
        break;
      case DeviceState.salvage:
        reasonText = "This device cannot be repaired.";
        break;
    }

    if(reasonText != null) {
      reportWidget = Text(reasonText, style: const TextStyle(fontSize: 20));
    } else {
      reportWidget = ReportProblemForm(deviceInfo: deviceInfo, updateDeviceInfo: _updateDeviceInfo,);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(widget.deviceInfo.device.type),
      ),
      body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20.0), child: Center(
        child: Card(
          child: Padding(padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${deviceInfo.device.manufacturer} ${deviceInfo.device.model}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  deviceInfo.device.orgUnit != null ? Text(deviceInfo.device.orgUnit!, style: const TextStyle(fontSize: 25)) : const Text(""),
                  const Divider(),
                  const SizedBox(height: 20),
                  deviceInfo.imageData != null && deviceInfo.imageData!.isNotEmpty ? Image.memory(base64Decode(deviceInfo.imageData!)) : const Text("no image available"),
                  const SizedBox(height: 30),
                  StateScreen(deviceInfo: deviceInfo),
                  const SizedBox(height: 20),
                  reportWidget,
                  const Divider(),
                  const Text("Available Documents:", style: TextStyle(fontSize: 25)),
                  const SizedBox(height: 10),
                  DocumentScreen(deviceInfo: deviceInfo),
                ]
              )
            )
          ),
        )
      ))
    ));
  }
}

class DocumentScreen extends StatefulWidget {
  final ShortDeviceInfo deviceInfo;

  const DocumentScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<String> _documents = [];

  final _scrollController = ScrollController();

  void _retrieveDocuments() {
    comm.retrieveDocuments(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model).then((documents) {//TODO catch Exception
      setState(() { _documents = documents; });
    });
  }

  void _downloadDocument(String docName) {
    String url = "${comm.getBaseUrl()}device_documents/${widget.deviceInfo.device.manufacturer}/${widget.deviceInfo.device.model}/$docName";
    html.AnchorElement anchorElement =  html.AnchorElement(href: url);
    anchorElement.download = docName;
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
        _documents.isNotEmpty ? Scrollbar(
          controller: _scrollController,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _documents.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Center(child: Text(_documents[index])),
                onTap: () => _downloadDocument(_documents[index])
              );
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
          )
        ) : const Center(child: Text('No documents found')),
      ]
    );
  }
}

class StateScreen extends StatefulWidget {
  final ShortDeviceInfo deviceInfo;

  const StateScreen({Key? key, required this.deviceInfo}) : super(key: key);

  @override
  State<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {

  @override
  Widget build(BuildContext context) {
    Report report = widget.deviceInfo.report;

    return Column(
      children: [
        Container(color: DeviceState.getColor(report.currentState),
          child: Padding(padding: const EdgeInsets.all(7.0),
            child: Row(children: [
                Icon(DeviceState.getIconData(report.currentState)),
                const SizedBox(width: 5),
                Text(DeviceState.getStateString(report.currentState),
                  style: const TextStyle(fontSize: 25)
                ),
                const Spacer(),
                Text("${DateTime.now().difference(report.created).inDays} days",
                  style: const TextStyle(fontSize: 25))
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

  const ReportProblemForm({Key? key, required this.deviceInfo, required this.updateDeviceInfo}) : super(key: key);

  @override
  State<ReportProblemForm> createState() => _ReportProblemFormState();
}

class _ReportProblemFormState extends State<ReportProblemForm> {
  final _formKey = GlobalKey<FormState>();

  final _reportTitleController = TextEditingController();
  final _problemTextController = TextEditingController();

  Future<bool> _createReport() async {
    if(_formKey.currentState!.validate()) {
      await comm.queueRepair(widget.deviceInfo.device.id, _reportTitleController.text, _problemTextController.text).then((newReport) {
        widget.updateDeviceInfo(ShortDeviceInfo(device: widget.deviceInfo.device, report: newReport, imageData: widget.deviceInfo.imageData));
      }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });

      return true;
    } else {
      return false;
    }
  }

  void _createReportDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return Form(key: _formKey,
            child: AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text("Report a problem", style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall),
                  TextFormField(
                    controller: _reportTitleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please give your report a title.";
                      }
                      return null;
                    },
                    maxLength: 25,
                    onFieldSubmitted: (value) => _createReport(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _problemTextController,
                      decoration: const InputDecoration(labelText: 'Problem description'),
                      maxLength: 600,
                      maxLines: null,
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
                  child: const Text('Request repair'),
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
    return ElevatedButton(
      onPressed: () => _createReportDialog(),
      child: const Text('Report a problem'),
    );
  }
}
