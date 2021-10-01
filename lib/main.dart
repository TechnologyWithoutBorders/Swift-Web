import 'package:flutter/material.dart';
import 'package:teog_swift/overviewScreen.dart';
import 'package:teog_swift/tabScreen.dart';
import 'package:teog_swift/aboutScreen.dart';
import 'package:teog_swift/constants.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'networkFunctions.dart' as Comm;
import 'preferenceManager.dart' as Prefs;
import 'hospital.dart';

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
  Hospital _hospitalValue;

  final _passwordTextController = TextEditingController();

  List<DropdownMenuItem<Hospital>> _hospitals = [];

  void _login() {
    if (_formKey.currentState.validate()) {
      String password = _passwordTextController.text;

      Comm.checkCredentials(_countryValue, _hospitalValue.id, password).then((success) {
        if(success) {
          List<int> bytes = utf8.encode(password);
          String hash = sha256.convert(bytes).toString();

          Prefs.save(_countryValue, _hospitalValue.id, hash).then((success) => Navigator.of(context).pushNamed(OverviewScreen.route));
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
    Widget input;

    if(_countryValue == 'Select Country') {
      input = DropdownButton<String>(//TODO: ListView draus machen
        value: _countryValue,
        icon: const Icon(Icons.expand_more),
        iconSize: 24,
        elevation: 16,
        onChanged: (String newValue) {
          _countryValue = newValue;

          Comm.getHospitals(newValue).then((hospitals) {
            setState(() {
              _hospitalValue = Hospital(id: -1, name: "Select Hospital");

              _hospitals = <DropdownMenuItem<Hospital>>[DropdownMenuItem(value: _hospitalValue, child: Text(_hospitalValue.name))];
              _hospitals.addAll(hospitals.map<DropdownMenuItem<Hospital>>((Hospital hospital) {
                return DropdownMenuItem<Hospital>(
                  value: hospital,
                  child: Text(hospital.name),
                );
              }).toList());
            });
          });
        },
        items: <String>['Select Country', 'Test']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      );
    } else if(_hospitalValue.id == -1) {
      input = DropdownButton<Hospital>(
        value: _hospitalValue,
        icon: const Icon(Icons.expand_more),
        iconSize: 24,
        elevation: 16,
        onChanged: (Hospital newValue) {
          _hospitalValue = newValue;
        },
        items: _hospitals,
      );
    } else {
      input = TextFormField(
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
        onFieldSubmitted: (value) => _login(),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sign in to report problems with devices or download user manuals.', style: Theme
              .of(context)
              .textTheme
              .headline5),
          input,
          SizedBox(height: 10),
            TextButton(//TODO: auch erst im letzten Step anzeigen
              style: ButtonStyle(
                foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Colors.white;
                }),
                backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Color(0xff667d9d);
                }),
              ),
              onPressed: () => _login(),
              child: Text('Login'),
            ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}