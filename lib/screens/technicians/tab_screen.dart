import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:teog_swift/main.dart';
import 'package:teog_swift/screens/technicians/dashBoardScreen.dart';
import 'package:teog_swift/screens/technicians/inventory_screen.dart';
import 'package:teog_swift/screens/technicians/organization_screen.dart';
import 'package:teog_swift/screens/technicians/user_management_screen.dart';
import 'package:teog_swift/screens/technicians/maintenance_screen.dart';

import 'package:teog_swift/utilities/preference_manager.dart' as prefs;
import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/hospital.dart';

class TabScreen extends StatefulWidget {
  static const String route = '/tabs';

  const TabScreen({Key? key}) : super(key: key);

  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  final _scrollController = ScrollController();
  
  String? _countryName;
  Hospital? _hospital;

  List<User>? _users;
  User? _user;

  void _logout(BuildContext context) async {
    await prefs.logout();
    Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
  }

  void _setHospitalInfo() async {
    String? countryName = await prefs.getCountry();
    Hospital? hospital = await comm.getHospitalInfo();

    setState(() {
      _countryName = countryName;
      _hospital = hospital;
    });
  }

  void _openMap() {
    if(_hospital != null) {
      html.window.open('https://www.openstreetmap.org/?mlat=${_hospital!.latitude}&mlon=${_hospital!.longitude}#map=17/${_hospital!.latitude}/${_hospital!.longitude}', 'map');
    }
  }

  @override
  void initState() {
    super.initState();

    _setHospitalInfo();

    comm.getUsers().then((users) => {
      setState(() {
        users.sort((a, b) => a.name.compareTo(b.name));

        _users = users;
      })
    });
  }

  void _saveUser(User user) async {
    await prefs.selectUser(user.id);

    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: Container(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: 0.3,
            heightFactor: 0.8,
            child: Card(
              child: Column(
                children: [
                  Text("Please select your user:",
                        style: Theme.of(context)
                          .textTheme
                          .headline4),
                  const SizedBox(height: 15),
                  Flexible(
                    child: _users != null ? Scrollbar(
                      controller: _scrollController,
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: _users!.length,
                        itemBuilder: (BuildContext context, int index) {
                          User user = _users![index];

                          return ListTile(
                            title: Text(user.name),
                            subtitle: Text(user.position),
                            onTap: () => _saveUser(user),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) => const Divider(),
                      ),
                    ) : const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                  )
                ]
              )
            )
          )
        )
      );
    } else {
      return DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: _hospital != null && _countryName != null ? Row(
              children: [
                Text("TeoG Swift - ${_hospital!.name}, ${_countryName!}"),
                IconButton(
                  tooltip: "show on map",
                  icon: const Icon(Icons.map),
                  onPressed: () => _openMap()
                )
              ]
            ) : const Text("TeoG Swift"),
            actions: [
              DropdownButton<User>(
                value: _user,
                selectedItemBuilder: (_) {
                  return _users!.map((user) => Container(
                    alignment: Alignment.center,
                    child: Text(
                      user.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )).toList();
                },
                items: _users!.map<DropdownMenuItem<User>>((User user) {
                    return DropdownMenuItem<User>(
                      value: user,
                      child: Text(
                        user.name,
                        style: const TextStyle(color: Colors.black),
                      )
                    );
                  }
                ).toList(),
                onChanged: (user) => {
                  if(user != null) {
                    _saveUser(user)
                  }
                },
              ),
              Padding(padding: const EdgeInsets.only(right: 20.0),
                child: TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? Colors.grey : Colors.white;
                    }),
                  ),
                  child: const Text("Logout"),
                  onPressed: () => {_logout(context)},
                )
              )
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: "Dashboard", icon: Icon(Icons.chair)),
                Tab(text: "Maintenance", icon: Icon(Icons.calendar_today)),
                Tab(text: "Inventory", icon: Icon(Icons.inventory)),
                Tab(text: "Organisation", icon: Icon(Icons.account_tree_outlined)),
                Tab(text: "People", icon: Icon(Icons.people)),
              ],
            ),
          ),
          body: const TabBarView(
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