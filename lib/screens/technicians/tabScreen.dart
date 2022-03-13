import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:teog_swift/main.dart';
import 'package:teog_swift/screens/technicians/dashBoardScreen.dart';
import 'package:teog_swift/screens/technicians/inventoryScreen.dart';
import 'package:teog_swift/screens/technicians/organizationScreen.dart';
import 'package:teog_swift/screens/technicians/userManagementScreen.dart';
import 'package:teog_swift/screens/technicians/maintenanceScreen.dart';

import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;
import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/hospital.dart';

class TabScreen extends StatefulWidget {
  static const String route = '/tabs';

  TabScreen({Key key}) : super(key: key);

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  final _scrollController = ScrollController();
  
  String _countryName;
  Hospital _hospital;

  List<User> _users = [];
  User _user;

  void _logout(BuildContext context) async {
    await Prefs.logout();
    Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
  }

  void _setHospitalInfo() async {
    String countryName = await Prefs.getCountry();
    Hospital hospital = await Comm.getHospitalInfo();

    setState(() {
      _countryName = countryName;
      _hospital = hospital;
    });
  }

  void _openMap() {
    if(_hospital != null) {
      html.window.open('https://www.openstreetmap.org/?mlat=' + _hospital.latitude.toString() + '&mlon=' + _hospital.longitude.toString() + '#map=17/' + _hospital.latitude.toString() + '/' + _hospital.longitude.toString(), 'map');
    }
  }

  @override
  void initState() {
    super.initState();

    _setHospitalInfo();

    Comm.getUsers().then((users) => {
      setState(() {
        _users = users;
      })
    });
  }

  void _saveUser(User user) async {
    await Prefs.selectUser(user.id);

    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_user == null) {
      return FractionallySizedBox(
        widthFactor: 0.3,
        heightFactor: 0.9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Please select your user:",
                  style: Theme.of(context)
                    .textTheme
                    .headline3),
            SizedBox(height: 15),
            Flexible(
              child: Card(
                child: Scrollbar(isAlwaysShown: true,
                  controller: _scrollController,
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: _users.length,
                    itemBuilder: (BuildContext context, int index) {
                      User user = _users[index];

                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.position),
                        onTap: () => _saveUser(user),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                  ),
                )
              )
            )
          ]
        )
      );
    } else {
      return DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: _hospital != null ? Row(
              children: [
                Text("TeoG Swift - "+ _hospital.name +  ", " + _countryName),
                IconButton(
                  tooltip: "show on map",
                  icon: Icon(Icons.map),
                  onPressed: () => _openMap()
                )
              ]
            ) : Text("TeoG Swift"),
            actions: [
              DropdownButton<User>(
                value: _user,
                selectedItemBuilder: (_) {
                  return _users.map((user) => Container(
                    alignment: Alignment.center,
                    child: Text(
                      user.name,
                      style: TextStyle(color: Colors.white),
                    ),
                  )).toList();
                },
                items: _users.map<DropdownMenuItem<User>>((User user) {
                    return DropdownMenuItem<User>(
                      value: user,
                      child: Text(
                        user.name,
                        style: TextStyle(color: Colors.black),
                      )
                    );
                  }
                ).toList(),
                onChanged: (user) => _saveUser(user),
              ),
              Padding(padding: EdgeInsets.only(right: 20.0),
                child: TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? null : Colors.white;
                    }),
                  ),
                  child: Text("Logout"),
                  onPressed: () => {_logout(context)},
                )
              )
            ],
            bottom: TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: "Dashboard", icon: Icon(Icons.chair)),
                Tab(text: "Maintenance", icon: Icon(Icons.calendar_today)),
                Tab(text: "Inventory", icon: Icon(Icons.inventory)),
                Tab(text: "Organization", icon: Icon(Icons.account_tree_outlined)),
                Tab(text: "People", icon: Icon(Icons.people)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              DashboardScreen(),
              MaintenanceScreen(),
              InventoryScreen(),
              OrganizationScreen(),
              UserManagementScreen(),
            ],
          ),
        ),
      );
    }
  }
}