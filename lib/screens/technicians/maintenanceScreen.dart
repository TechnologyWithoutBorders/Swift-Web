import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;

class MaintenanceScreen extends StatefulWidget {
  MaintenanceScreen({Key key}) : super(key: key);

  @override
  _MaintenanceScreenState createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {

  DateTime _selectedDay;
  Map<DateTime, List<HospitalDevice>> maintenanceEvents = Map();

  @override
  void initState() {
    super.initState();

    _initEvents();
  }

  Future<void> _initEvents() async {
    
    
    setState(() {
     
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
              focusedDay: now,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              eventLoader: (day) {
                return maintenanceEvents[day];
              },
            )
          )
        )
      )
    );
  }
}