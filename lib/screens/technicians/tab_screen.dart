import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:teog_swift/main.dart';
import 'package:teog_swift/screens/technicians/dashboard_screen.dart';
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

  Image? _hospitalImage;

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

    comm.getUsers().then((users) {
      List<User> validUsers = [];

      for(var user in users) {
        if(user.valid) {
          validUsers.add(user);
        }
      }

      validUsers.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _users = validUsers;
      });
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
      if(_hospitalImage == null) {
        comm.getHospitalImage().then((image) {
          setState(() {
            _hospitalImage = image;
          });
        });
      }

      return Scaffold(
        backgroundColor: Colors.grey[200],
        body: Container(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: 0.7,
            heightFactor: 0.8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                            child: _hospital != null ? Text(
                              _hospital!.name,
                              style: Theme.of(context).textTheme.headlineMedium
                              ) : const Text("loading..."),
                          ),
                          _hospitalImage != null ? Flexible(child: _hospitalImage!) : const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                        ]
                      )
                    )
                  )
                ),
                Flexible(child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text("Please select your name in the list:",
                          style: Theme.of(context)
                            .textTheme
                            .headlineSmall),
                      ),
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
                )),
              ]
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
                    foregroundColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
                      return states.contains(WidgetState.disabled) ? Colors.grey : Colors.white;
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
                Tab(text: "Dashboard", icon: Icon(Icons.query_stats)),
                Tab(text: "Maintenance", icon: Icon(Icons.calendar_today)),
                Tab(text: "Inventory", icon: Icon(Icons.inventory)),
                Tab(text: "Organisation", icon: Icon(Icons.account_tree_outlined)),
                Tab(text: "Settings", icon: Icon(Icons.settings)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              DashboardScreen(user: _user!),
              MaintenanceScreen(user: _user!),
              InventoryScreen(user: _user!),
              OrganizationScreen(user: _user!),
              const UserManagementScreen(),
            ],
          ),
        ),
      );
    }
  }
}