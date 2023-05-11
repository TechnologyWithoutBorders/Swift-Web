import 'package:flutter/material.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/message_exception.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _DetailScreenState();
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
        return AlertDialog(
          title: const Text("The user will receive his/her password for the mobile app via email.\nPlease check the spam folder if it does not show up."),
          contentPadding: const EdgeInsets.all(16.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name'),
                maxLength: 30,
              ),
              TextField(
                controller: mailController,
                decoration: const InputDecoration(
                  labelText: 'Mail Address'),
                maxLength: 50,
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

                  if(name.isNotEmpty && mail.isNotEmpty) {
                    comm.createUser(mail, name).then((_) {
                      _updateUsers();
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

    _updateUsers();
  }

  void _updateUsers() {
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
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _deleteUser(User user) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure you want to delete this user?"),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Delete'),
                onPressed: () {
                  final User deletedUser = User(
                    id: user.id,
                    name: user.name,
                    phone: user.phone,
                    mail: user.mail,
                    position: user.position,
                    valid: false
                  );

                  comm.editUser(deletedUser).then((_) {
                    _updateUsers();
                  }).onError<MessageException>((error, stackTrace) {
                    final snackBar = SnackBar(content: Text(error.message));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  });

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
            child: Padding(padding: const EdgeInsets.all(25.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Center(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Manage Staff", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              itemCount: _users.length,
                              itemBuilder: (BuildContext context, int index) {
                                User user = _users[index];

                                return ListTile(
                                  title: SelectableText(user.name),
                                  subtitle: SelectableText("${user.position}\n${user.mail}\n${user.phone}"),
                                  trailing: TextButton(child: const Icon(Icons.delete, color: Colors.red), onPressed: () =>_deleteUser(user)),
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15,),
                        ElevatedButton(
                          onPressed: () => _createUser(),
                          child: const Text('Register user'),
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