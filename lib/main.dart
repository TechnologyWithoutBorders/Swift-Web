import 'package:flutter/material.dart';
import 'package:teog_swift/overviewScreen.dart';
import 'package:teog_swift/tabScreen.dart';
import 'package:teog_swift/aboutScreen.dart';
import 'package:teog_swift/constants.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'networkFunctions.dart' as Comm;
import 'preferenceManager.dart' as Prefs;

void main() => runApp(SwiftApp());

class SwiftApp extends StatelessWidget {
  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.app_name,
      initialRoute: SwiftApp.route,
      routes: {
        SwiftApp.route: (context) => LoginScreen(),
        OverviewScreen.route: (context) => OverviewScreen(),
        AboutScreen.route: (context) => AboutScreen(),
        TabScreen.route: (context) => TabScreen(),
      },
      theme: ThemeData(
        primaryColor: Color(0xFF01265D),
        buttonTheme: ButtonThemeData(
           colorScheme: Theme.of(context).colorScheme.copyWith(primary: Colors.red, secondary: Colors.white, background: Colors.yellow),//TODO das klappt nicht
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: AssetImage('graphics/logo.png')),
              SizedBox(height: 10),
              Card(child: Padding(padding: EdgeInsets.all(10.0), child: LoginForm())),
              SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  String _countryValue = 'Select Country';//TODO: use cookie + get from server
  String _hospitalValue = "1";

  final _passwordTextController = TextEditingController();

  void _loginMedical() {
    if (_formKey.currentState.validate()) {
      String password = _passwordTextController.text;

      Comm.checkCredentials(_countryValue, int.parse(_hospitalValue), password).then((success) {
        if(success) {
          List<int> bytes = utf8.encode(password);
          String hash = sha256.convert(bytes).toString();

          Prefs.save(_countryValue, int.parse(_hospitalValue), hash).then((success) => Navigator.of(context).pushNamed(OverviewScreen.route));
        }
      }).onError((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.data));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  void _loginTechnician() {
    if (_formKey.currentState.validate()) {
      String password = _passwordTextController.text;

      Comm.checkCredentials(_countryValue, int.parse(_hospitalValue), password).then((success) {
        if(success) {
          List<int> bytes = utf8.encode(password);
          String hash = sha256.convert(bytes).toString();

          Prefs.save(_countryValue, int.parse(_hospitalValue), hash).then((success) => Navigator.of(context).pushNamed(TabScreen.route));
        }
      }).onError((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.data));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Prefs.checkLogin(syncWithServer: true).then((success) { 
      if(success) {//TODO: das funktioniert nicht
        Navigator.of(context).pushNamed(OverviewScreen.route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sign in to report problems with devices or download user manuals.', style: Theme
              .of(context)
              .textTheme
              .headline5),
          DropdownButton<String>(
            value: _countryValue,
            icon: const Icon(Icons.expand_more),
            iconSize: 24,
            elevation: 16,
            onChanged: (String newValue) {
              setState(() {
                _countryValue = newValue;
              });
            },
            items: <String>['Select Country', 'Test']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            value: _hospitalValue,
            icon: const Icon(Icons.expand_more),
            iconSize: 24,
            elevation: 16,
            onChanged: (String newValue) {
              setState(() {
                _hospitalValue = newValue;
              });
            },
            items: <String>['1']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          TextFormField(
            controller: _passwordTextController,
            decoration: InputDecoration(hintText: 'Password'),
            obscureText: true,
            autofocus: true,
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          Row(children: [
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Colors.white;
                }),
                backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Color(0xff667d9d);
                }),
              ),
              onPressed: () => _loginMedical(),
              child: Text('Login as medical staff'),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Colors.white;
                }),
                backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Color(0xff667d9d);
                }),
              ),
              onPressed: () => _loginTechnician(),
              child: Text('Login as technician'),
            )
          ]),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}