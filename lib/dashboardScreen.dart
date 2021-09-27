import 'package:flutter/material.dart';

import 'package:charts_flutter/flutter.dart' as charts;

import 'networkFunctions.dart' as Comm;
import 'deviceInfo.dart';
import 'package:teog_swift/deviceInfoScreen.dart';
import 'package:teog_swift/deviceState.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DashboardScreen> {
  final _scrollController = ScrollController();

  List<DeviceInfo> _devices = [];

  @override
  void initState() {
    super.initState();

    Comm.getTodoDevices().then((devices) {//TODO catch Exception
      setState(() {
        _devices = devices;
      });
    });
  }

  void _openDeviceById(int id) {
    Comm.fetchDevice(id).then((deviceInfo) {//TODO catch Exception
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(deviceInfo: deviceInfo),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(width: 400, height: 600,
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(height: 400, width: 100, child: DatumLegendWithMeasures.withSampleData()),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("TODO", style: Theme
                            .of(context)
                            .textTheme
                            .headline5),
                          SizedBox(height: 500, width: 600,
                            child: Scrollbar(isAlwaysShown: true,
                              controller: _scrollController,
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemCount: _devices.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    leading: Container(width: 30, height: 30, color: DeviceState.getColor(_devices[index].report.currentState),
                                      child: Padding(padding: EdgeInsets.all(3.0),
                                        child: Row(children: [
                                            Icon(DeviceState.getIconData(_devices[index].report.currentState))
                                          ]
                                        )
                                      )
                                    ),
                                    title: Text(_devices[index].device.type),
                                    subtitle: Text(_devices[index].device.manufacturer + " " + _devices[index].device.model),
                                    trailing: Text(_devices[index].device.location),
                                    onTap: () => _openDeviceById(_devices[index].device.id)
                                  );
                                },
                                separatorBuilder: (BuildContext context, int index) => const Divider(),
                              ),
                            ),
                          ),
                          TextButton(
                            child: Text('Create new device?'),
                            onPressed: () => {},
                          ),
                        ]
                      )
                    ]
                  )
                ),
              )     
            ]
          )
        )
      )
    );
  }
}

class DatumLegendWithMeasures extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  DatumLegendWithMeasures(this.seriesList, {this.animate});

  factory DatumLegendWithMeasures.withSampleData() {
    return new DatumLegendWithMeasures(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(
      seriesList,
      animate: animate,
      behaviors: [
        new charts.DatumLegend(
          position: charts.BehaviorPosition.end,
          horizontalFirst: false,
          cellPadding: new EdgeInsets.only(right: 4.0, bottom: 4.0),
          showMeasures: true,
          legendDefaultMeasure: charts.LegendDefaultMeasure.firstValue,
          measureFormatter: (num value) {
            return value == null ? '-' : '${value}k';
          },
        ),
      ],
    );
  }

  /// Create series list with one series
  static List<charts.Series<CategoryData, String>> _createSampleData() {
    final data = [
      new CategoryData(DeviceState.getStateString(DeviceState.working), 128, charts.ColorUtil.fromDartColor(DeviceState.getColor(DeviceState.working))),
      new CategoryData(DeviceState.getStateString(DeviceState.maintenance), 83, charts.ColorUtil.fromDartColor(DeviceState.getColor(DeviceState.maintenance))),
      new CategoryData(DeviceState.getStateString(DeviceState.broken), 15, charts.ColorUtil.fromDartColor(DeviceState.getColor(DeviceState.broken))),
    ];

    return [
      new charts.Series<CategoryData, String>(
        id: 'Categories',
        domainFn: (CategoryData categoryData, _) => categoryData.category,
        measureFn: (CategoryData categoryData, _) => categoryData.count,
        colorFn: (CategoryData categoryData, _) => categoryData.color,
        data: data,
      )
    ];
  }
}

class CategoryData {
  final String category;
  final int count;
  final charts.Color color;

  CategoryData(this.category, this.count, this.color);
}
