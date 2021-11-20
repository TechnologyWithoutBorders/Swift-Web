import 'package:flutter/material.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/user.dart';

class InventoryScreen extends StatefulWidget {
  InventoryScreen({Key key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();
  final _mailTextController = TextEditingController();

  final _scrollController = ScrollController();

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
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Users", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(child: Padding(padding: EdgeInsets.all(15.0),
                          child: Scrollbar(isAlwaysShown: true,
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(3),
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
                        )),
                      ]
                    )
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Text('Register a new user', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(child: Padding(padding: EdgeInsets.all(15.0), child: Form(key: _formKey,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FractionallySizedBox(widthFactor: 0.6,
                                child: TextFormField(
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
                              ),
                              FractionallySizedBox(widthFactor: 0.6,
                                child: TextFormField(
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
                              ),
                              SizedBox(height: 10,),
                              ElevatedButton(
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
                        ))
                      )]
                    ),
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