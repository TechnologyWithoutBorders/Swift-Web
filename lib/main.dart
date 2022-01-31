import 'package:flutter/material.dart';
import 'package:teog_swift/screens/overviewScreen.dart';
import 'package:teog_swift/screens/technicians/tabScreen.dart';
import 'package:teog_swift/screens/aboutScreen.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:teog_swift/utilities/country.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;
import 'package:teog_swift/utilities/hospital.dart';
import 'package:teog_swift/utilities/messageException.dart';

import 'package:flag/flag.dart';

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
        appBarTheme: AppBarTheme(
          backgroundColor: Color(Constants.teog_blue),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Color(Constants.teog_blue_light)
          )
        )
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(Constants.app_name)
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(padding: EdgeInsets.all(10.0), child: Image(image: AssetImage('graphics/logo.png'))),
              SizedBox(height: 10),
              Card(child: Padding(padding: EdgeInsets.all(10.0), child: LoginForm())),
              SizedBox(height: 30),
              TextButton(onPressed: () => Navigator.of(context).pushNamed(AboutScreen.route),
                child: Text('About'),),
              SizedBox(height: 100),
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

  final _countryScrollController = ScrollController();//TODO: use cookie
  List<Country> _countries = [];
  Country _selectedCountry;

  final _hospitalScrollController = ScrollController();
  List<Hospital> _hospitals = [];
  Hospital _selectedHospital;

  final _passwordTextController = TextEditingController();

  void _login() {
    if (_formKey.currentState.validate()) {
      String password = _passwordTextController.text;

      Comm.checkCredentials(_selectedCountry.name, _selectedHospital.id, password).then((role) {
        String route;

        if(role == Constants.role_technical) {
          route = TabScreen.route;
        } else if(role == Constants.role_medical) {
          route = OverviewScreen.route;
        }

        List<int> bytes = utf8.encode(password);
        String hash = sha256.convert(bytes).toString();

        Prefs.save(_selectedCountry.name, _selectedHospital.id, role, hash).then((success) => Navigator.pushNamedAndRemoveUntil(context, route, (r) => false));
      }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedCountry = null;
      _selectedHospital = null;
      _hospitals.clear();
    });
  }

  @override
  void initState() {
    super.initState();

    Prefs.checkLogin(syncWithServer: true).then((role) { 
      if(role == Constants.role_medical) {
        Navigator.pushNamedAndRemoveUntil(context, OverviewScreen.route, (r) => false);
      } else if(role == Constants.role_technical) {
        Navigator.pushNamedAndRemoveUntil(context, TabScreen.route, (r) => false);
      } else {
        Comm.getCountries().then((countries) {
          setState(() { _countries = countries; });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget input;

    if(_selectedHospital == null) {
      input = Row(
        children: [
          Flexible(
            child: Column(
              children: [
                Text("Country",
                  style: Theme.of(context)
                    .textTheme
                    .headline5),
                Flexible(
                  child: ListView.separated(
                    controller: _countryScrollController,
                    padding: const EdgeInsets.all(5),
                    itemCount: _countries.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        leading: Flag.fromString(_countries[index].code, height: 35, width: 35),
                        title: Text(_countries[index].name),
                        onTap: () => {
                          Comm.getHospitals(_countries[index].name).then((hospitals) {
                            setState(() {
                              _selectedCountry = _countries[index];
                              _hospitals = hospitals;
                            });
                          })
                        }
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                  )
                )
              ]
            )
          ),
          Flexible(
            child: Column(
              children: [
                Text("Hospital",
                  style: Theme.of(context)
                    .textTheme
                    .headline5),
                Flexible(
                  child: ListView.separated(
                    controller: _hospitalScrollController,
                    padding: const EdgeInsets.all(5),
                    itemCount: _hospitals.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(_hospitals[index].name),
                        subtitle: Text(_hospitals[index].location),
                        onTap: () => {
                          setState(() {
                            _selectedHospital = _hospitals[index];
                          })
                        }
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                  )
                )
              ]
            )
          )
        ]
      );
    } else {
      input = Center(
        child: Column(
          children:[
            SizedBox(height: 10),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children:[
                Flag.fromString(_selectedCountry.code, height: 35, width: 35),
                Text(_selectedCountry.name + ' - ' + _selectedHospital.name, style: TextStyle(fontSize: 20)),
                IconButton(
                  iconSize: 20,
                  icon: Icon(Icons.cancel_outlined, color: Colors.red[700]),
                  onPressed: () => _clearSelection(), 
                )
              ]
            ),
            SizedBox(height: 10),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: TextFormField(
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
              )
            )
          ]
        )
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
              .headline6),
          SizedBox(height: 15),
          SizedBox(height: 300,
            child: input
          ),
          SizedBox(height: 10),
            ElevatedButton(//TODO: auch erst im letzten Step anzeigen
              onPressed: () => _login(),
              child: Text('Login'),
            ),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}