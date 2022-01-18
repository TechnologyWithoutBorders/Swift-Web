import 'package:flutter/material.dart';

import 'package:teog_swift/screens/technicians/userManagementScreen.dart';
import 'package:teog_swift/screens/technicians/organizationScreen.dart';

class AdminScreen extends StatelessWidget {
  AdminScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(25.0),
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: "Organization", icon: Icon(Icons.chair)),
                      Tab(text: "People", icon: Icon(Icons.calendar_today)),
                    ],
                  ),
                  TabBarView(
                    children: [
                      OrganizationScreen(),
                      UserManagementScreen(),
                    ],
                  )
                ]
              )
            )
          )
        )
      )
    )
    );
  }
}