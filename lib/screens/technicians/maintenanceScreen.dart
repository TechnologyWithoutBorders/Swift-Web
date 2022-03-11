import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/maintenanceEvent.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;

class MaintenanceScreen extends StatefulWidget {
  MaintenanceScreen({Key key}) : super(key: key);

  @override
  _MaintenanceScreenState createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {

  DateTime _focusedDay = DateTime.now(), _selectedDay;
  Map<String, List<HospitalDevice>> _maintenanceEvents = Map();

  @override
  void initState() {
    super.initState();

    _initEvents();
  }

  Future<void> _initEvents() async {
    List<MaintenanceEvent> events = await Comm.getMaintenanceEvents();

    Map<String, List<HospitalDevice>> maintenanceEvents = Map();

    for(var event in events) {
      if(maintenanceEvents.containsKey(event.dateTime.toString())) {
        maintenanceEvents[event.dateTime.toString()].add(event.device);
      } else {
        maintenanceEvents[event.dateTime.toString()] = [event.device];
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
                      lastDay: now.add(Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      eventLoader: (day) {
                        return _maintenanceEvents[day.toString()];
                      },
                      headerStyle: HeaderStyle(
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
                      calendarStyle: CalendarStyle(
                        weekendTextStyle: TextStyle(color: Colors.redAccent),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if(events.length > 0) {
                            return Container(color: Color(Constants.teog_blue_light), child: Padding(padding: EdgeInsets.all(1), child: Text(events.length.toString() + " devices", style: TextStyle(fontSize: 14.0))));
                          } else {
                            return null;
                          }
                        },
                      )
                    )
                  )
                ),
                Expanded(child: Center(child: Text("The devices will be shown here in the future if you click on a date.")))
              ]
            )
          )
        )
      )
    );
  }
}