import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/deviceInfo.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/messageException.dart';

class ReportHistoryPlot extends StatefulWidget {
  final OrganizationalUnit? orgUnit;

  ReportHistoryPlot({Key? key, this.orgUnit}) : super(key: key);

  @override
  _ReportHistoryPlotState createState() => _ReportHistoryPlotState();
}

class _ReportHistoryPlotState extends State<ReportHistoryPlot> {
  List<DeviceInfo>? _deviceInfos;

  final _orgScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Comm.getAllDeviceInfos().then((deviceInfos) {
      setState(() {
        _deviceInfos = deviceInfos;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        print(error.message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(alignment: Alignment.center,
      child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(25.0),
            child: _deviceInfos != null ? Center(
              child: Scrollbar(
                controller: _orgScrollController,
                child: SingleChildScrollView(
                  controller: _orgScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                    ]
                  )
                )
              )
            ) : Center(child: Text("crunching data..."))
          )
        )
      )
    );
  }
}