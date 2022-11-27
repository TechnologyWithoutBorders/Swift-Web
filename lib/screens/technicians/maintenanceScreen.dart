import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/maintenanceEvent.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/screens/technicians/technicianDeviceScreen.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as comm;

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _scrollController = ScrollController();

  List<HospitalDevice> _selectedDevices = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<HospitalDevice>> _maintenanceEvents = {};

  @override
  void initState() {
    super.initState();

    _initEvents();
  }

  Future<void> _initEvents() async {
    List<MaintenanceEvent> events = await comm.getMaintenanceEvents();

    Map<String, List<HospitalDevice>> maintenanceEvents = {};

    for(var event in events) {
      String key = event.dateTime.toString().substring(0, 10);

      if(maintenanceEvents.containsKey(key)) {
        maintenanceEvents[key]!.add(event.device);
      } else {
        maintenanceEvents[key] = [event.device];
      }
    }
    
    setState(() {
      _maintenanceEvents = maintenanceEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: 
      Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 5.0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                      side: BorderSide( color: Colors.black, width: 1.0),
                    ),
                    child: TableCalendar(
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      weekendDays: const [DateTime.saturday, DateTime.sunday],//TODO: define per locale
                      daysOfWeekHeight: 40.0,
                      firstDay: now,
                      lastDay: now.add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        List<HospitalDevice> selectedDevices = [];

                        String key = selectedDay.toString().substring(0, 10);

                        if(_maintenanceEvents.containsKey(key)) {
                          selectedDevices.addAll(_maintenanceEvents[key]!);
                        }

                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _selectedDevices = selectedDevices;
                        });
                      },
                      eventLoader: (day) {
                        String key = day.toString().substring(0, 10);

                        if(_maintenanceEvents.containsKey(key)) {
                          return _maintenanceEvents[key]!;
                        } else {
                          return [];
                        }
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20.0),
                        decoration: BoxDecoration(
                          color: Color(Constants.teog_blue),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)
                          )
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekendStyle: TextStyle(color: Colors.redAccent),
                      ),
                      calendarStyle: const CalendarStyle(
                        weekendTextStyle: TextStyle(color: Colors.redAccent),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if(events.isNotEmpty) {
                            return Container(color: const Color(Constants.teog_blue_light), child: Padding(padding: const EdgeInsets.all(1), child: Text("${events.length} devices", style: const TextStyle(fontSize: 14.0))));
                          } else {
                            return null;
                          }
                        },
                      )
                    )
                  )
                ),
                Expanded(
                  child: _selectedDevices.isNotEmpty ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _selectedDay != null ? Text(_selectedDay.toString().substring(0, 10), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)) : const Text(""),
                        Flexible(child: Padding(padding: const EdgeInsets.all(10.0),
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(3),
                              itemCount: _selectedDevices.length,
                              itemBuilder: (BuildContext context, int index) {
                                HospitalDevice device = _selectedDevices[index];

                                return ListTile(
                                  title: Text(device.type),
                                  subtitle: Text("${device.manufacturer} ${device.model}"),
                                  trailing: device.orgUnit != null ? Text(device.orgUnit!) : null,
                                  onTap: () => {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianDeviceScreen(id: device.id)))
                                  }
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        )),
                      ]
                    )
                  ) : const Center(child: Text("Click on a date in the calendar to show the devices that need maintenance."))
                )
              ]
            )
          )
        )
      )
    );
  }
}