import 'package:flutter/material.dart';

import 'package:teog_swift/main.dart';
import 'package:teog_swift/screens/technicians/codeGenerationScreen.dart';
import 'package:teog_swift/screens/technicians/dashBoardScreen.dart';
import 'package:teog_swift/screens/technicians/userManagementScreen.dart';

import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;

class TabScreen extends StatelessWidget {
  static const String route = '/tabs';

  TabScreen({Key key}) : super(key: key);

  void _logout(BuildContext context) async {
    await Prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          actions: [
            Padding(padding: EdgeInsets.only(right: 30.0),
              child: TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                    return states.contains(MaterialState.disabled) ? null : Colors.white;
                  }),
                ),
                child: Text("Logout"),
                onPressed: () => _logout(context),
              )
            )
          ],
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
    );
  }
}