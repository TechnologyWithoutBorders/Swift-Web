import 'package:flutter/material.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/messageException.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<UserManagementScreen> {
  final _scrollController = ScrollController();

  List<User> _users = [];

  void _createUser() {
    //TODO: should those be disposed?
    TextEditingController nameController = TextEditingController();
    TextEditingController mailController = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text("The user will receive his/her password for the mobile app via email.\nPlease check the spam folder if it does not show up."),
          contentPadding: const EdgeInsets.all(16.0),
          content: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: new InputDecoration(
                  labelText: 'Name'),
              ),
              TextField(
                controller: mailController,
                decoration: new InputDecoration(
                  labelText: 'Mail Address'),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Register'),
                onPressed: () {
                  String name = nameController.text;
                  String mail = mailController.text;

                  if (name.isNotEmpty && mail.isNotEmpty) {
                    Comm.createUser(mail, name).then((users) {
                      setState(() {
                        users.sort((a, b) => a.name.compareTo(b.name));

                        _users = users;
                      });
                    }).onError<MessageException>((error, stackTrace) {
                      final snackBar = SnackBar(content: Text(error.message));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    });
                  }

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();

    Comm.getUsers().then((users) {
      setState(() {
        users.sort((a, b) => a.name.compareTo(b.name));

        _users = users;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _deleteUser() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text("Are you sure you want to delete this user? (Does nothing at the moment)"),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Delete'),
                onPressed: () {
                  //TODO: implement

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
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
                    child: Center(),
                  ),
                  Expanded(
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
                                User user = _users[index];

                                return ListTile(
                                  title: SelectableText(user.name),
                                  subtitle: SelectableText(user.mail + "\n" + user.phone),
                                  //trailing: TextButton(child: Icon(Icons.delete), onPressed: () =>_deleteUser()),
                                  trailing: Text(_users[index].position),
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        ),
                        SizedBox(height: 15,),
                        ElevatedButton(
                          onPressed: () => _createUser(),
                          child: Text('Register user'),
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