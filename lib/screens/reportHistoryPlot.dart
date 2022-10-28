import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/detailedReport.dart';
import 'package:teog_swift/utilities/deviceState.dart';

import 'package:charts_flutter/flutter.dart' as charts;
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
  List<charts.Series<CategoryData, int>>? _seriesList;

  @override
  void initState() {
    super.initState();

    Comm.getAllDeviceInfos().then((deviceInfos) {
      DateTime earliest = DateTime.now();

      //find earliest report
      for(var deviceInfo in deviceInfos) {
        List<DetailedReport> reports = deviceInfo.reports;

        if(reports.last.created.isBefore(earliest)) {
          earliest = DateTime(reports.last.created.year, reports.last.created.month, reports.last.created.day);
        }
      }
      
      //iterate over days
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      int days = today.difference(earliest).inDays;

      List<List<CategoryData>> dataList = [[], [], [], [], [], []];

      for(int day = 0; day <= days+1; day++) {
        DateTime current = earliest.add(Duration(days: day));

        var stateCounters = [0, 0, 0, 0, 0, 0];

        //find current state of every device
        for(var deviceInfo in deviceInfos) {
          List<DetailedReport> reports = deviceInfo.reports;
          reports = reports.reversed.toList();

          DetailedReport lastReport = reports.first;

          for(var report in reports) {
            if(report.created.isBefore(current)) {
              if(report.created.isAfter(lastReport.created)) {
                lastReport = report;
              }
            } else {
              break;
            }
          }

          stateCounters[lastReport.currentState] = stateCounters[lastReport.currentState]+1;
        }

        print(stateCounters);

        for(int state = 0; state < 6; state++) {
          dataList[state].add(new CategoryData(day, stateCounters[state], charts.ColorUtil.fromDartColor(DeviceState.getColor(state))));
        }
      }

      List<charts.Series<CategoryData, int>> seriesList = [];

      for(int state = 0; state < 6; state++) {
        seriesList.add(
          new charts.Series<CategoryData, int>(
            id: DeviceState.getStateString(state),
            domainFn: (CategoryData categoryData, _) => categoryData.category,
            measureFn: (CategoryData categoryData, _) => categoryData.count,
            colorFn: (CategoryData categoryData, _) => categoryData.color,
            data: dataList[state],
            labelAccessorFn: (CategoryData categoryData, _) => '${categoryData.category}: ${categoryData.count}',
        ));
      }

      setState(() {
        _seriesList = seriesList;
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
            child: _seriesList != null ? Center(
              child: Center(child: StateLineChart(_seriesList!))
            ) : Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
          )
        )
      )
    );
  }
}

class StateLineChart extends StatelessWidget {
  final List<charts.Series<dynamic, int>> seriesList;

  StateLineChart(this.seriesList);

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(
      seriesList,
      defaultRenderer: new charts.LineRendererConfig(includeArea: true, stacked: true),
    );
  }
}

class CategoryData {
  final int category;
  final int count;
  final charts.Color color;

  CategoryData(this.category, this.count, this.color);
}