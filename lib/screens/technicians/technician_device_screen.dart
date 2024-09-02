import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/device_info.dart';
import 'package:teog_swift/utilities/detailed_report.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/message_exception.dart';

import 'package:file_picker/file_picker.dart';

class TechnicianDeviceScreen extends StatefulWidget {
  final User user;
  final int deviceId;

  final ValueChanged<DeviceInfo> onReportCreated;

  const TechnicianDeviceScreen({Key? key, required this.user, required this.deviceId, required this.onReportCreated}) : super(key: key);

  @override
  State<TechnicianDeviceScreen> createState() => _TechnicianDeviceScreenState();
}

class _TechnicianDeviceScreenState extends State<TechnicianDeviceScreen> {

  DeviceInfo? _deviceInfo;

  @override
  void initState() {
    super.initState();

    comm.getDeviceInfo(widget.deviceId).then((deviceInfo) {
      setState(() {
        _deviceInfo = deviceInfo;
      });
    });
  }

  _updateDeviceInfo(DeviceInfo modifiedDeviceInfo) {
    setState(() {
      _deviceInfo = modifiedDeviceInfo;
    });

    widget.onReportCreated(modifiedDeviceInfo);
  }

  @override
  Widget build(BuildContext context) {
    if(_deviceInfo == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 2, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _deviceInfo!.imageData != null && _deviceInfo!.imageData!.isNotEmpty ? Image.memory(base64Decode(_deviceInfo!.imageData!)) : const Text("no image available")),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SelectableText("${_deviceInfo!.device.manufacturer} ${_deviceInfo!.device.model}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  _deviceInfo!.device.orgUnit != null ? Text(_deviceInfo!.device.orgUnit!, style: const TextStyle(fontSize: 25)) : const Text(""),
                  SelectableText("Serial number: ${_deviceInfo!.device.serialNumber}"),
                  Text("Maintenance interval: ${_deviceInfo!.device.maintenanceInterval/4} months"),
                ]
              )),
            ]
          )),
          const SizedBox(height: 10),
          Expanded(flex: 3, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: ReportHistoryScreen(deviceInfo: _deviceInfo!, user: widget.user, updateDeviceInfo: _updateDeviceInfo)),
              Expanded(child: DocumentScreen(deviceInfo: _deviceInfo!))
            ]
          )),
        ]
      );
    }
  }
}

class ReportHistoryScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;
  final User user;

  final ValueChanged<DeviceInfo> updateDeviceInfo;

  const ReportHistoryScreen({Key? key, required this.deviceInfo, required this.user, required this.updateDeviceInfo}) : super(key: key);

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final _scrollController = ScrollController();

  final _formKey = GlobalKey<FormState>();

  final _reportTitleController = TextEditingController();
  final _problemTextController = TextEditingController();

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
                  DetailedReport report = reports[index];
                  // Flutter does not support date formatting without libraries
                  String dateStamp = report.created.toString().substring(0, report.created.toString().length-7);

                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(dateStamp, textAlign: report.authorId == widget.user.id ? TextAlign.right : TextAlign.left),
                        Card(
                          color: report.authorId == widget.user.id ? const Color(Constants.teogBlueLighter) : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(report.authorId == widget.user.id ? "You:" : "${report.author}:")),
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
          onPressed: () => _createReportDialog(latestReport.currentState),
        ),
      ]
    );
  }

  Future<bool> _createReport(int state) async {
    if(_formKey.currentState!.validate()) {
      await comm.createReport(widget.deviceInfo.device.id, _reportTitleController.text, _problemTextController.text, state).then((newReport) {
        List<DetailedReport> newReports = List<DetailedReport>.from(widget.deviceInfo.reports);
        newReports.add(newReport);

        DeviceInfo modifiedDeviceInfo = DeviceInfo(device: widget.deviceInfo.device, reports: newReports, imageData: widget.deviceInfo.imageData);

        widget.updateDeviceInfo(modifiedDeviceInfo);
      }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });

      return true;
    } else {
      return false;
    }
  }

  void _createReportDialog(int initialState) {
    int state = initialState;

    showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return Form(key: _formKey,
          child: AlertDialog(
            contentPadding: const EdgeInsets.all(16.0),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("Create a report", style: Theme
                        .of(context)
                        .textTheme
                        .headlineSmall),
                    const SizedBox(height: 10),
                    DropdownButton<int>(
                      hint: const Text("State"),
                      value: state,
                      onChanged: (int? selectedState) {
                        if(selectedState != null) {
                          setState(() {
                            state = selectedState;
                          });
                        }
                      },
                      items: [0, 1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((int selectedState) {
                        return DropdownMenuItem<int>(
                          value: selectedState,
                          child: Row(
                            children: [
                              Container(width: 33, height: 33, color: DeviceState.getColor(selectedState),
                                child: Padding(padding: const EdgeInsets.all(4.0),
                                  child: Icon(DeviceState.getIconData(selectedState),
                                      size: 25,
                                      color: Colors.grey[900]
                                    )
                                )
                              ),
                              const SizedBox(width: 10),
                              Text(DeviceState.getStateString(selectedState))
                            ]
                          )
                        );
                      }).toList(),
                    ),
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
                      onFieldSubmitted: (value) => _createReport(state),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _problemTextController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLength: 600,
                        maxLines: null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please describe the problem in a few sentences.";
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) => _createReport(state),
                      ),
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
                  }
              ),
              ElevatedButton(
                child: const Text('Create report'),
                onPressed: () async {
                  bool success = await _createReport(state);
                  
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
    setState(() {
      _documents.clear();
    });

    comm.retrieveDocuments(widget.deviceInfo.device.manufacturer, widget.deviceInfo.device.model).then((documents) {
      setState(() { _documents = documents; });
    }).onError<MessageException>((error, stackTrace) {
      //ignore
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
  void didUpdateWidget(DocumentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(widget.deviceInfo.device.id != oldWidget.deviceInfo.device.id) {
      _retrieveDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget uploadWidget;

    if(_uploading) {
      uploadWidget = const CircularProgressIndicator(value: null);
    } else {
      uploadWidget = ElevatedButton(
        child: const Text("Upload documents"),
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
