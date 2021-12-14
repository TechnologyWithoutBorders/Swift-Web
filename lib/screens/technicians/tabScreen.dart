import 'package:flutter/material.dart';

import 'package:teog_swift/main.dart';
import 'package:teog_swift/screens/technicians/dashBoardScreen.dart';
import 'package:teog_swift/screens/technicians/inventoryScreen.dart';
import 'package:teog_swift/screens/technicians/administrationScreen.dart';

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
          title: Text('Swift'),
          actions: [
            Padding(padding: EdgeInsets.only(right: 20.0),
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
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Dashboard", icon: Icon(Icons.chair)),
              Tab(text: "Inventory", icon: Icon(Icons.inventory)),
              Tab(text: "Administration", icon: Icon(Icons.person)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DashboardScreen(),
            InventoryScreen(),
            UserManagementScreen(),
          ],
        ),
      ),
    );
  }
}