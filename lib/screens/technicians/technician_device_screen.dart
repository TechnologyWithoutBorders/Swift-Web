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
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/message_exception.dart';

import 'package:file_picker/file_picker.dart';

class TechnicianDeviceScreen extends StatefulWidget {
  final User user;
  final DeviceInfo deviceInfo;

  const TechnicianDeviceScreen({Key? key, required this.user, required this.deviceInfo}) : super(key: key);

  @override
  State<TechnicianDeviceScreen> createState() => _TechnicianDeviceScreenState();
}

class _TechnicianDeviceScreenState extends State<TechnicianDeviceScreen> {

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 2, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: widget.deviceInfo.imageData != null && widget.deviceInfo.imageData!.isNotEmpty ? Image.memory(base64Decode(widget.deviceInfo.imageData!)) : const Text("no image available")),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SelectableText("${widget.deviceInfo.device.manufacturer} ${widget.deviceInfo.device.model}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                widget.deviceInfo.device.orgUnit != null ? Text(widget.deviceInfo.device.orgUnit!, style: const TextStyle(fontSize: 25)) : const Text(""),
                SelectableText("Serial number: ${widget.deviceInfo.device.serialNumber}"),
                Text("Maintenance interval: ${widget.deviceInfo.device.maintenanceInterval/4} months"),
              ]
            )),
          ]
        )),
        const SizedBox(height: 10),
        Expanded(flex: 3, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: ReportHistoryScreen(deviceInfo: widget.deviceInfo, user: widget.user)),
            Expanded(child: DocumentScreen(deviceInfo: widget.deviceInfo))
          ]
        )),
      ]
    );
  }
}

class ReportHistoryScreen extends StatefulWidget {
  final DeviceInfo deviceInfo;
  final User user;

  const ReportHistoryScreen({Key? key, required this.deviceInfo, required this.user}) : super(key: key);

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final _scrollController = ScrollController();

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
    anchorElement.download = url;
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
