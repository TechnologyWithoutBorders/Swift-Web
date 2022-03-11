import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/maintenanceEvent.dart';

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
      maintenanceEvents[event.dateTime.toString()] = [event.device];
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
            child: TableCalendar(
              firstDay: now.subtract(Duration(days: 30)),
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
            )
          )
        )
      )
    );
  }
}