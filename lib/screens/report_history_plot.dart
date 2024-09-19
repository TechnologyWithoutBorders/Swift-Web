import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/detailed_report.dart';
import 'package:teog_swift/utilities/device_state.dart';

import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/organizational_unit.dart';
import 'package:teog_swift/utilities/message_exception.dart';

class ReportHistoryPlot extends StatefulWidget {
  final OrganizationalUnit? orgUnit;

  const ReportHistoryPlot({Key? key, this.orgUnit}) : super(key: key);

  @override
  State<ReportHistoryPlot> createState() => _ReportHistoryPlotState();
}

class _ReportHistoryPlotState extends State<ReportHistoryPlot> {
  List<List<CategoryData>>? _dataList;

  @override
  void initState() {
    super.initState();

    comm.getAllDeviceInfos().then((deviceInfos) {
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

          DetailedReport? relevantReport;

          for(var report in reports) {
            if(report.created.isBefore(current)) {
              if(relevantReport == null) {
                relevantReport = report;
              } else if(report.created.isAfter(relevantReport.created)) {
                relevantReport = report;
              }
            } else {
              break;
            }
          }

          if(relevantReport != null) {
            stateCounters[relevantReport.currentState] = stateCounters[relevantReport.currentState]+1;
          }
        }

        for(int state = 0; state < 6; state++) {
          dataList[state].add(CategoryData(current, stateCounters[state], charts.ColorUtil.fromDartColor(DeviceState.getColor(state))));
        }
      }

      setState(() {
        _dataList = dataList;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<charts.Series<CategoryData, DateTime>>? seriesList;

    if(_dataList != null) {
      seriesList = [];

      for(int state = 0; state < 6; state++) {
        seriesList.add(
          charts.Series<CategoryData, DateTime>(
            id: DeviceState.getStateString(state),
            domainFn: (CategoryData categoryData, _) => categoryData.category,
            measureFn: (CategoryData categoryData, _) => categoryData.count,
            colorFn: (CategoryData categoryData, _) => categoryData.color,
            data: _dataList![state],
            labelAccessorFn: (CategoryData categoryData, _) => '${categoryData.category}: ${categoryData.count}',
        ));
      }
    }

    return Dialog(alignment: Alignment.center,
      child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: seriesList != null ? Center(
              child: Center(child: charts.TimeSeriesChart(
                seriesList,
                behaviors: [
                  charts.SeriesLegend()
                ])
              )
            ) : const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
          )
        )
      )
    );
  }
}

class CategoryData {
  final DateTime category;
  final int count;
  final charts.Color color;

  CategoryData(this.category, this.count, this.color);
}