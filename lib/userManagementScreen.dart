import 'package:flutter/material.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();

  void _createUser() {
    if (_formKey.currentState.validate()) {
      String userName = _nameTextController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(width: 400, height: 350,
          child: Card(
            child: Padding(padding: EdgeInsets.all(10.0),
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
            )
          )
        ),
      )
    );
  }
}