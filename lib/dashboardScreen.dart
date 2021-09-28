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
  List<DeviceInfo> _todoDevices = [];

  @override
  void initState() {
    super.initState();

    Comm.getDevices().then((devices) {//TODO: catch Exception
      setState(() {
        _devices = devices;

        _todoDevices.clear();

        _devices.forEach((deviceInfo) {
          int currentState = deviceInfo.report.currentState;

          if(currentState == DeviceState.broken || currentState == DeviceState.maintenance || currentState == DeviceState.inProgress) {
            _todoDevices.add(deviceInfo);
          }
        });
      });
    });
  }

  void _openDeviceById(int id) {
    Comm.fetchDevice(id).then((deviceInfo) {//TODO: catch Exception
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
    var countList = [0, 0, 0, 0, 0, 0];

    _devices.forEach((deviceInfo) {
      countList[deviceInfo.report.currentState] += 1;
    });

    final data = [];

    for(int state = 0; state < countList.length; state++) {
      if(countList[state] > 0) {
        data.add(new CategoryData(DeviceState.getStateString(state), countList[state], charts.ColorUtil.fromDartColor(DeviceState.getColor(state))));
      }
    }

    List<charts.Series<CategoryData, String>> seriesList = [
      new charts.Series<CategoryData, String>(
        id: 'Categories',
        domainFn: (CategoryData categoryData, _) => categoryData.category,
        measureFn: (CategoryData categoryData, _) => categoryData.count,
        colorFn: (CategoryData categoryData, _) => categoryData.color,
        data: data,
        labelAccessorFn: (CategoryData categoryData, _) => '${categoryData.category}: ${categoryData.count}',
    )];

    return Scaffold(
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.8, heightFactor: 0.8,
          child: Card(
            child: Padding(padding: EdgeInsets.all(25.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Categories", style: Theme
                          .of(context)
                          .textTheme
                          .headline4),
                        Flexible(child: Padding(padding: EdgeInsets.all(25.0), child: DatumLegendWithMeasures(seriesList))),
                        Text("xy devices are due for maintenance", style: Theme
                          .of(context)
                          .textTheme
                          .headline6),
                      ]
                    )
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("TODO", style: Theme
                          .of(context)
                          .textTheme
                          .headline4),
                        Flexible(child: Padding(padding: EdgeInsets.all(10.0),
                          child: Scrollbar(isAlwaysShown: true,
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _todoDevices.length,
                              itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                  leading: Container(width: 30, height: 30, color: DeviceState.getColor(_todoDevices[index].report.currentState),
                                    child: Padding(padding: EdgeInsets.all(3.0),
                                      child: Row(children: [
                                          Icon(DeviceState.getIconData(_todoDevices[index].report.currentState))
                                        ]
                                      )
                                    )
                                  ),
                                  title: Text(_todoDevices[index].device.type),
                                  subtitle: Text(_todoDevices[index].device.manufacturer + " " + _todoDevices[index].device.model),
                                  trailing: Text(_todoDevices[index].device.location),
                                  onTap: () => _openDeviceById(_todoDevices[index].device.id)
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        )),
                        TextButton(
                          child: Text('Create new device?'),
                          onPressed: () => {},
                        )
                      ]
                    )
                  )
                ]
              )
            ),
          )     
        )
      )
    );
  }
}

class DatumLegendWithMeasures extends StatelessWidget {
  final List<charts.Series> seriesList;

  DatumLegendWithMeasures(this.seriesList);

  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(
      seriesList,
      defaultRenderer: new charts.ArcRendererConfig(arcRendererDecorators: [
          new charts.ArcLabelDecorator(
              labelPosition: charts.ArcLabelPosition.outside)
        ])
    );
  }
}

class CategoryData {
  final String category;
  final int count;
  final charts.Color color;

  CategoryData(this.category, this.count, this.color);
}
