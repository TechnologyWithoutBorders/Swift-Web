import 'package:flutter/material.dart';
import 'package:teog_swift/deviceInfoScreen.dart';
import 'package:teog_swift/main.dart';

import 'networkFunctions.dart' as Comm;
import 'preference_manager.dart' as Prefs;
import 'hospitalDevice.dart';
import 'doubleCardLayout.dart';

class OverviewScreen extends StatelessWidget {
  static const String route = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome', style: Theme
            .of(context)
            .textTheme
            .headline3),
          Text('Please tell us which device you are looking for', style: Theme
            .of(context)
            .textTheme
            .headline5),
          SizedBox(height: 25),
          DoubleCardLayout(DoubleCardLayout.horizontal, SearchForm(), "OR", FilterForm()),
        ])
      ),
    );
  }
}

class SearchForm extends StatefulWidget {
  @override
  _SearchFormState createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _formKey = GlobalKey<FormState>();

  final _deviceIDController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Prefs.checkLogin().then((success) {
      
      if(!success) {
        Navigator.of(context).pushNamed(SwiftApp.route);
      }
    });
  }

  ///Validates whether a given [value] is a valid device ID.
  ///
  ///Returns null if value is valid, otherwise text message.
  String validateDeviceID(String value) {
    if(value.isNotEmpty) {
      var numeric = int.tryParse(value);

      if(numeric != null && numeric > 0) {
        return null;
      } else {
        return "Please enter a valid barcode number";
      }
    } else {
      return "Please enter a barcode number";
    }
  }

  void _processDeviceId() {
    if (_formKey.currentState.validate()) {
      Comm.fetchDevice(int.parse(_deviceIDController.text)).then((deviceInfo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(deviceInfo: deviceInfo),
          )
        );
      }).onError((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey,
      child: SizedBox(width: 250,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('By entering a barcode number', style: Theme
              .of(context)
              .textTheme
              .headline5),
          SizedBox(height: 10),
          Text("This is the easiest way. Please look for a barcode like this:"),
          Image(image: AssetImage('graphics/barcode.jpg')),
          TextFormField(
            controller: _deviceIDController,
            decoration: InputDecoration(hintText: 'Barcode Number'),
            keyboardType: TextInputType.number,
            autofocus: true,
            validator: (value) => validateDeviceID(value),
            onFieldSubmitted: (value) => _processDeviceId(),
          ),
          SizedBox(height: 10),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                return states.contains(MaterialState.disabled) ? null : Colors.white;
              }),
              backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                return states.contains(MaterialState.disabled) ? null : Colors.blue;
              }),
            ),
            onPressed: () => _processDeviceId(),
            child: Text('Search'),
          ),
        ],
      ),
    ));
  }
}

class FilterForm extends StatefulWidget {
  @override
  _FilterFormState createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  final _formKey = GlobalKey<FormState>();

  final _typeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _locationController = TextEditingController();

  final _scrollController = ScrollController();

  List<HospitalDevice> _filteredDevices = [];

  String validateDeviceID(String value) {
    return null;//TODO:
    /*if(value.isNotEmpty) {
      var numeric = int.tryParse(value);

      if(numeric != null && numeric > 0) {
        return null;
      } else {
        return "Please enter a valid barcode number";
      }
    } else {
      return "Please enter a barcode number";
    }*/
  }

  void _processInput() {
    if (_formKey.currentState.validate()) {
      Comm.searchDevices(_typeController.text, _manufacturerController.text, _locationController.text).then((devices) {//TODO catch Exception
        setState(() { _filteredDevices = devices; });
      });
    }
  }

  void _openDeviceById(int id) {
    Comm.fetchDevice(id).then((deviceInfo) {//TODO catch Exception
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(deviceInfo: deviceInfo),
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey,
      child: SizedBox(width: 350,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('By searching', style: Theme
              .of(context)
              .textTheme
              .headline5),
          TextFormField(
            controller: _typeController,
            decoration: InputDecoration(hintText: 'Device type (e.g. "Ventilator")'),
            autofocus: true,
            validator: (value) => validateDeviceID(value),
            onFieldSubmitted: (value) => _processInput(),
          ),
          TextFormField(
            controller: _manufacturerController,
            decoration: InputDecoration(hintText: 'Manufacturer'),
            validator: (value) => validateDeviceID(value),
            onFieldSubmitted: (value) => _processInput(),
          ),
          TextFormField(decoration: InputDecoration(hintText: 'Location (not working yet)')),//TODO: nur für Sortierung, da oft nicht hinterlegt
          SizedBox(height: 10),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                return states.contains(MaterialState.disabled) ? null : Colors.white;
              }),
              backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                return states.contains(MaterialState.disabled) ? null : Colors.blue;
              }),
            ),
            onPressed: () => _processInput(),
            child: Text('Filter'),
          ),
          SizedBox(height: 10),
          Text(_filteredDevices.length.toString() + " device(s) match the filter:"),
          SizedBox(height: 10),
          SizedBox(height: 250,
            child: Scrollbar(isAlwaysShown: true,
              controller: _scrollController,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _filteredDevices.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    leading: FlutterLogo(size: 56.0),
                    title: Text(_filteredDevices[index].type),
                    subtitle: Text(_filteredDevices[index].manufacturer + " " + _filteredDevices[index].model),
                    trailing: Text(_filteredDevices[index].location),
                    onTap: () => _openDeviceById(_filteredDevices[index].id)
                  );
                },
                separatorBuilder: (BuildContext context, int index) => const Divider(),
              ),
            )
          ),
        ],
      ),
    ));
  }
}