import 'package:flutter/material.dart';

import 'package:charts_flutter/flutter.dart' as charts;

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/shortDeviceInfo.dart';
import 'package:teog_swift/screens/technicians/technicianDeviceScreen.dart';
import 'package:teog_swift/utilities/deviceState.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DashboardScreen> {
  final _scrollController = ScrollController();

  List<ShortDeviceInfo> _devices = [];
  List<ShortDeviceInfo> _todoDevices = [];

  @override
  void initState() {
    super.initState();

    _updateDevices();
  }

  void _updateDevices() {
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

  @override
  Widget build(BuildContext context) {
    var countList = [0, 0, 0, 0, 0, 0];

    _devices.forEach((deviceInfo) {
      countList[deviceInfo.report.currentState] += 1;
    });

    final List<CategoryData> data = [];

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
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: EdgeInsets.all(25.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Overview", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(child: Padding(padding: EdgeInsets.all(30.0), child: DatumLegendWithMeasures(seriesList))),
                        Text("xy devices are due for maintenance", style: TextStyle(fontSize: 20)),
                      ]
                    )
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("ToDo", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(child: Padding(padding: EdgeInsets.all(10.0),
                          child: Scrollbar(isAlwaysShown: true,
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(3),
                              itemCount: _todoDevices.length,
                              itemBuilder: (BuildContext context, int index) {
                                ShortDeviceInfo deviceInfo = _todoDevices[index];

                                return ListTile(
                                  leading: Container(width: 30, height: 30, color: DeviceState.getColor(deviceInfo.report.currentState),
                                    child: Padding(padding: EdgeInsets.all(3.0),
                                      child: Row(children: [
                                          Icon(DeviceState.getIconData(deviceInfo.report.currentState))
                                        ]
                                      )
                                    )
                                  ),
                                  title: Text(deviceInfo.device.type),
                                  subtitle: Text(deviceInfo.device.manufacturer + " " + deviceInfo.device.model),
                                  trailing: Text(deviceInfo.device.location),
                                  onTap: () => {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianDeviceScreen(id: deviceInfo.device.id))).then((value) => {
                                      //this is called when the newly created route returns
                                      _updateDevices()
                                    })
                                  }
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        )),
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
