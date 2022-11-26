import 'package:flutter/material.dart';
import 'package:teog_swift/screens/overviewScreen.dart';
import 'package:teog_swift/screens/technicians/tabScreen.dart';
import 'package:teog_swift/utilities/constants.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:teog_swift/utilities/country.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;
import 'package:teog_swift/utilities/hospital.dart';
import 'package:teog_swift/utilities/messageException.dart';

import 'package:flag/flag.dart';

import 'package:package_info_plus/package_info_plus.dart';

void main() => runApp(const SwiftApp());

class SwiftApp extends StatelessWidget {
  static const String route = '/';

  const SwiftApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.app_name,
      initialRoute: SwiftApp.route,
      routes: {
        SwiftApp.route: (context) => const LoginScreen(),
        OverviewScreen.route: (context) => const OverviewScreen(),
        TabScreen.route: (context) => const TabScreen(),
      },
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(Constants.teog_blue),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(Constants.teog_blue_light)
          )
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: MaterialStateProperty.all<bool>(true),
        )
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
        _packageInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();

    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(Constants.app_name)
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              const Flexible(flex: 6, child: Padding(padding: EdgeInsets.all(10.0), child: Image(image: AssetImage(Constants.logo_path)))),
              const Spacer(),
              const Flexible(flex: 20, child: Card(child: Padding(padding: EdgeInsets.all(10.0), child: LoginForm()))),
              const Spacer(),
              TextButton(
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: _packageInfo.appName,
                  applicationVersion: " v${_packageInfo.version}-${_packageInfo.buildNumber}",
                  applicationIcon: const Image(image: AssetImage(Constants.logo_path))
                ),
                child: const Text('About'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _countryScrollController = ScrollController();
  List<Country> _countries = [];
  Country? _selectedCountry;

  final _hospitalScrollController = ScrollController();
  List<Hospital> _hospitals = [];
  Hospital? _selectedHospital;

  final _passwordTextController = TextEditingController();

  void _login() {
    String? countryName = _selectedCountry?.name;
    int? hospitalId = _selectedHospital?.id;

    if(countryName != null && hospitalId != null && _formKey.currentState!.validate()) {
      String password = _passwordTextController.text;

      Comm.checkCredentials(countryName, hospitalId, password).then((role) {
        String? route;

        if(role == Constants.role_technical) {
          route = TabScreen.route;
        } else if(role == Constants.role_medical) {
          route = OverviewScreen.route;
        }

        if(route != null) {
          List<int> bytes = utf8.encode(password);
          String hash = sha256.convert(bytes).toString();
          Prefs.save(countryName, hospitalId, role, hash).then((success) => Navigator.pushNamedAndRemoveUntil(context, route!, (r) => false));
        } else {
          const snackBar = SnackBar(content: Text("could not determine role of user"));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
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

  void _checkForPreferences() async{
    List<Country> countries = await Comm.getCountries();
    for (var i = 0; i < countries.length; i++) {
      if (countries[i].name == await Prefs.getCountry()) {
        _selectedCountry = countries[i];
        List<Hospital> hospitals = await Comm.getHospitals(countries[i].name);
        for (var j = 0; j < hospitals.length; j++) {
          if (hospitals[j].id == await Prefs.getHospital()) {
            _selectedHospital = hospitals[j];
          }
        }
      }
    }
    setState(() {
      _countries = countries;
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
        _checkForPreferences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget input;

    if(_selectedCountry == null || _selectedHospital == null) {
      input = Row(
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Country",
                  style: Theme.of(context)
                    .textTheme
                    .headline5),
                Flexible(
                  child: Scrollbar(
                    controller: _countryScrollController,
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
                )
              ]
            )
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Hospital",
                  style: Theme.of(context)
                    .textTheme
                    .headline5),
                Flexible(
                  child: Scrollbar(
                    controller: _hospitalScrollController,
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
            const SizedBox(height: 10),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children:[
                Flag.fromString(_selectedCountry!.code, height: 35, width: 35),
                Text('${_selectedCountry!.name} - ${_selectedHospital!.name}', style: const TextStyle(fontSize: 20)),
                IconButton(
                  iconSize: 20,
                  icon: Icon(Icons.cancel_outlined, color: Colors.red[700]),
                  onPressed: () => _clearSelection(), 
                )
              ]
            ),
            const SizedBox(height: 10),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: TextFormField(
                controller: _passwordTextController,
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
          const SizedBox(height: 15),
          Flexible(
            child: Center(child: input)
          ),
          const SizedBox(height: 10),
          _selectedHospital != null ? ElevatedButton(
            onPressed: () => _login(),
            child: const Text('Login'),
          ) : const SizedBox(),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}