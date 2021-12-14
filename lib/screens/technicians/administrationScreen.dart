import 'package:flutter/material.dart';

import 'dart:html' as html;

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/hospital.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();
  final _mailTextController = TextEditingController();

  final _scrollController = ScrollController();

  Hospital _hospital;
  List<User> _users = [];

  void _createUser() {
    if (_formKey.currentState.validate()) {
      String name = _nameTextController.text;
      String mail = _mailTextController.text;

      Comm.createUser(mail, name).then((users) {
        setState(() {
          _users = users;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Comm.getHospitalInfo().then((hospital) {//TODO: catch Exception
      setState(() {
        _hospital = hospital;
      });
    });

    Comm.getUsers().then((users) {//TODO: catch Exception
      setState(() {
        _users = users;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: EdgeInsets.all(25.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        _hospital == null ? Text("") : Text(_hospital.name, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        _hospital == null ? Text("") : Text(_hospital.location, style: TextStyle(fontSize: 20)),
                        _hospital == null ? Text("") : TextButton(onPressed: () => {
                            html.window.open('https://www.openstreetmap.org/?mlat=' + _hospital.latitude.toString() + '&mlon=' + _hospital.longitude.toString() + '#map=17/' + _hospital.latitude.toString() + '/' + _hospital.longitude.toString(), 'map')
                          }, child: Icon(Icons.map)),
                        _hospital == null ? Text("") : TextButton(onPressed: () => {
                            html.window.open('https://www.openstreetmap.org/?mlat=' + _hospital.latitude.toString() + '&mlon=' + _hospital.longitude.toString() + '#map=17/' + _hospital.latitude.toString() + '/' + _hospital.longitude.toString(), 'map')
                          }, child: Text("show on map")),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Manage Staff", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(
                          child: Scrollbar(isAlwaysShown: true,
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              itemCount: _users.length,
                              itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                  title: Text(_users[index].name),
                                  subtitle: Text(_users[index].mail),
                                  trailing: Text(_users[index].position),
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        ),
                        SizedBox(height: 15,),
                        Text('Register a new technician', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Form(key: _formKey,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: _nameTextController,
                                decoration: InputDecoration(hintText: 'Name'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the name of the user';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (value) => _createUser(),
                              ),
                              TextFormField(
                                controller: _mailTextController,
                                decoration: InputDecoration(hintText: 'Mail Address'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the mail address of the user';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (value) => _createUser(),
                              ),
                              SizedBox(height: 10,),
                              ElevatedButton(
                                onPressed: () => _createUser(),
                                child: Text('Register user'),
                              )
                            ]
                          )
                        )
                      ]
                    )
                  ),
                ]
              )
            ),
          )     
        )
      )
    );
  }
}