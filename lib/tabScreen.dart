import 'package:flutter/material.dart';

import 'package:teog_swift/codeGenerationScreen.dart';
import 'package:teog_swift/dashBoardScreen.dart';
import 'package:teog_swift/userManagementScreen.dart';

class TabScreen extends StatelessWidget {
  static const String route = '/tabs';

  TabScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(text: "Dashboard", icon: Icon(Icons.chair)),
                Tab(text: "Print Barcodes", icon: Icon(Icons.print)),
                Tab(text: "User Management", icon: Icon(Icons.person)),
              ],
            ),
            title: Text('Swift'),
          ),
          body: TabBarView(
            children: [
              DashboardScreen(),
              CodeGenerationScreen(),
              UserManagementScreen(),
            ],
          ),
        ),
      ),
    );
  }
}