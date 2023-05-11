import 'package:flutter/material.dart';

import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:teog_swift/utilities/device_stats.dart';
import 'package:teog_swift/utilities/hospital_device.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/screens/technicians/technician_device_screen.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/detailed_report.dart';
import 'package:teog_swift/utilities/message_exception.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DashboardScreen> {
  final _scrollController = ScrollController();
  final _activityScrollController = ScrollController();

  DeviceStats? _deviceStats;
  List<ShortDeviceInfo>? _todoDevices;
  List<DetailedReport>? _recentReports;

  @override
  void initState() {
    super.initState();

    _updateDevices();
  }

  void _updateDevices() {
    comm.getTodoDevices().then((todoDevices) {
      todoDevices.sort((a, b) => b.report.created.compareTo(a.report.created));

      setState(() {
        _todoDevices = todoDevices;
      });
    }).onError<MessageException>((error, stackTrace) {
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    comm.getDeviceStats().then((deviceStats) {
      setState(() {
        _deviceStats = deviceStats;
      });
    }).onError<MessageException>((error, stackTrace) {
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    comm.getRecentActivity().then((reports) {
      setState(() {
        _recentReports = reports;
      });
    }).onError<MessageException>((error, stackTrace) {
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  /*void _registerDevice() {
    int? selectedState = DeviceState.working;

    //TODO: should those be disposed?
    TextEditingController idController = TextEditingController();
    TextEditingController typeController = TextEditingController();
    TextEditingController manufacturerController = TextEditingController();
    TextEditingController modelController = TextEditingController();
    TextEditingController stateController = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) { 
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey)
                    ),
                    child: Padding(padding: const EdgeInsets.all(10), child: TextField(
                      controller: idController,
                      decoration: const InputDecoration(
                        helperMaxLines: 2,
                        helperText: "Leave empty to determine ID automatically.",//TODO: make user select explicitly
                        labelText: 'ID',
                      ),
                    ))
                  ),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type'),
                  ),
                  TextField(
                    controller: manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer'),
                  ),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model'),
                  ),
                  Padding(padding: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () {}, child: const Text("Choose location..."))),
                  //TODO: select location via organizational chart
                  DropdownButton<int>(
                    hint: const Text("Current state"),
                    value: selectedState,
                    items: <int>[0, 1, 2, 3, 4, 5]//TODO: das sollte aus DeviceStates kommen
                      .map<DropdownMenuItem<int>>((int state) {
                        return DropdownMenuItem<int>(
                          value: state,
                          child: Container(
                            color: DeviceState.getColor(state),
                            child: Row(
                              children: [
                                Icon(DeviceState.getIconData(state)),
                                const SizedBox(width: 5),
                                Text(DeviceState.getStateString(state)),
                              ]
                            )
                          ),
                        );
                      }
                    ).toList(),
                    onChanged: (newValue) => {
                      setState(() {
                        selectedState = newValue;
                      })
                    },
                  ),
                  selectedState != DeviceState.working ? TextField(
                    controller: stateController,
                    decoration: const InputDecoration(
                      labelText: 'Description'),
                  ) : const SizedBox.shrink()
                ],
              );
            }
          ),
          actions: [
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Register'),
                onPressed: () {
                  String type = typeController.text;
                  String manufacturer = manufacturerController.text;
                  String model = modelController.text;

                  /*Comm.editDevice(
                    HospitalDevice(id: this._deviceInfo.device.id, type: type, manufacturer: manufacturer, model: model, location: location)).then((modifiedDeviceInfo) {
                    
                    _updateDeviceInfo(modifiedDeviceInfo);
                  });*/ //TODO:

                  Navigator.pop(context);
                })
          ],
        );
      }
    ).then((value) => _updateDevices());
  }*/

  @override
  Widget build(BuildContext context) {
    List<charts.Series<CategoryData, String>> seriesList = [];

    if(_deviceStats != null) {
      var stateOrder = [DeviceState.working, DeviceState.inProgress, DeviceState.maintenance, DeviceState.broken, DeviceState.limitations, DeviceState.salvage];
      var stateList = [_deviceStats!.working, _deviceStats!.progress, _deviceStats!.maintenance, _deviceStats!.broken, _deviceStats!.limitations, _deviceStats!.salvage];

      final List<CategoryData> data = [];

      for(int state = 0; state < stateList.length; state++) {
        if(stateList[state] > 0) {
          data.add(CategoryData(DeviceState.getStateString(stateOrder[state]), stateList[state], charts.ColorUtil.fromDartColor(DeviceState.getColor(stateOrder[state]))));
        }
      }

      seriesList = [
        charts.Series<CategoryData, String>(
          id: 'Categories',
          domainFn: (CategoryData categoryData, _) => categoryData.category,
          measureFn: (CategoryData categoryData, _) => categoryData.count,
          colorFn: (CategoryData categoryData, _) => categoryData.color,
          data: data,
          labelAccessorFn: (CategoryData categoryData, _) => '${categoryData.category}: ${categoryData.count}',
      )];
    }

    DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: const EdgeInsets.all(25.0),
              child: _deviceStats != null && _todoDevices != null && _recentReports != null ? Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Overview", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(child: Padding(padding: const EdgeInsets.all(30.0), child: StatePieChart(seriesList))),
                        _deviceStats!.maintenanceOverdue > 0 ? Container(
                          padding: const EdgeInsets.all(3.0),
                          color: const Color(Constants.lightRed),
                          child: Text("${_deviceStats!.maintenanceOverdue} devices are overdue for maintenance", style: const TextStyle(fontSize: 20))
                        ) : Container(),
                      ]
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("ToDo", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(child: Padding(padding: const EdgeInsets.all(10.0),
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(3),
                              itemCount: _todoDevices!.length,
                              itemBuilder: (BuildContext context, int index) {
                                ShortDeviceInfo deviceInfo = _todoDevices![index];
                                HospitalDevice device = deviceInfo.device;
                                Report report = deviceInfo.report;

                                int days = now.difference(report.created).inDays;

                                return ListTile(
                                  leading: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(width: 33, height: 33, color: DeviceState.getColor(report.currentState),
                                        child: Padding(padding: const EdgeInsets.all(4.0),
                                          child: Icon(DeviceState.getIconData(report.currentState),
                                              size: 25,
                                              color: Colors.grey[900]
                                            )
                                        )
                                      ),
                                      const SizedBox(height: 1),
                                      Text("$days d", style: const TextStyle(fontSize: 12, color: Color(Constants.infoGreen)))
                                    ]
                                  ),
                                  title: Text(device.type),
                                  subtitle: Text("${device.manufacturer} ${device.model}"),
                                  trailing: device.orgUnit != null ? Text(device.orgUnit!) : null,
                                  onTap: () => {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianDeviceScreen(id: device.id))).then((value) => {
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
                        /*SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () => _registerDevice(),
                          child: Text("Register new device")
                        )*/
                      ]
                    )
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Recent Activity", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Flexible(
                          child: _recentReports!.isNotEmpty ? Container(
                            color: Colors.grey[200],
                            child: Scrollbar(
                              controller: _activityScrollController,
                              child: ListView.separated(
                                controller: _activityScrollController,
                                itemCount: _recentReports!.length,
                                itemBuilder: (BuildContext context, int index) {
                                  DetailedReport report = _recentReports![index];
                                  // Flutter does not support date formatting without libraries
                                  String dateStamp = report.created.toString().substring(0, report.created.toString().length-7);

                                  return Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(dateStamp),
                                        InkWell(
                                          child: Card(
                                            color: Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(5.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(child: Text("${report.author}:")),
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
                                          ),
                                          onTap: () => {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianDeviceScreen(id: report.deviceId))).then((value) => {
                                              //this is called when the newly created route returns
                                              _updateDevices()
                                            })
                                          }
                                        )
                                      ]
                                    )
                                  );
                                },
                                separatorBuilder: (BuildContext context, int index) => Container(),
                              ),
                            ),
                          ) : const Center(child: Text("no activity in the last 7 days"))
                        ),
                      ]
                    )
                  )
                ]
              ) : const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
            ),
          )
        )
      )
    );
  }
}

class StatePieChart extends StatelessWidget {
  final List<charts.Series<dynamic, String>> seriesList;

  const StatePieChart(this.seriesList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return charts.PieChart<String>(
      seriesList,
      behaviors: [
        charts.DatumLegend(
          position: charts.BehaviorPosition.bottom,
          horizontalFirst: false,
          cellPadding: const EdgeInsets.only(right: 10.0, top: 4.0),
          showMeasures: true,
          desiredMaxRows: 3,
          legendDefaultMeasure: charts.LegendDefaultMeasure.firstValue,
          measureFormatter: (num? value) {
            return value == null ? '-' : value.toString();
          }
        )
      ]
    );
  }
}

class CategoryData {
  final String category;
  final int count;
  final charts.Color color;

  CategoryData(this.category, this.count, this.color);
}
