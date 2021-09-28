import 'package:flutter/material.dart';

import 'user.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();

  final _scrollController = ScrollController();

  List<User> _users = [];

  void _createUser() {
    if (_formKey.currentState.validate()) {
      String userName = _nameTextController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.8, heightFactor: 0.8,
          child: Card(
            child: Padding(padding: EdgeInsets.all(25.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Form(key: _formKey,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Register a new user', style: Theme
                            .of(context)
                            .textTheme
                            .headline5),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _nameTextController,
                            decoration: InputDecoration(hintText: 'Name of user'),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                            onFieldSubmitted: (value) => _createUser(),
                          ),
                          SizedBox(height: 5),
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                                return states.contains(MaterialState.disabled) ? null : Colors.white;
                              }),
                              backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                                return states.contains(MaterialState.disabled) ? null : Color(0xff667d9d);
                              }),
                            ),
                            onPressed: () => _createUser(),
                            child: Text('Register user'),
                          )
                        ]
                      )
                    )
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Users", style: Theme
                          .of(context)
                          .textTheme
                          .headline4),
                        Flexible(child: Padding(padding: EdgeInsets.all(10.0),
                          child: Scrollbar(isAlwaysShown: true,
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _users.length,
                              itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                  title: Text(_users[index].name),
                                  subtitle: Text(_users[index].position),
                                  //TODO: onTap: () => _openDeviceById(_todoDevices[index].device.id)
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        )),
                      ]
                    )
                  )
                ]
              )
            ),
          )     
        )
      )
    );
  }
}