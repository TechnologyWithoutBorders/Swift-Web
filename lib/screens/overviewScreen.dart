import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:teog_swift/main.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/previewDeviceInfo.dart';
import 'package:teog_swift/screens/deviceInfoScreen.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/doubleCardLayout.dart';

import 'package:teog_swift/utilities/sessionMixin.dart';
import 'package:teog_swift/utilities/messageException.dart';

import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;
import 'package:teog_swift/utilities/hospital.dart';
import 'package:teog_swift/screens/organizationFilterView.dart';

class OverviewScreen extends StatefulWidget {
  static const String route = '/welcome';

  OverviewScreen({Key? key}) : super(key: key);

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String _countryName;
  Hospital _hospital;

  void _logout(BuildContext context) async {
    await Prefs.logout();
    Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
  }

  void _setHospitalInfo() async {
    String countryName = await Prefs.getCountry();
    Hospital hospital = await Comm.getHospitalInfo();

    setState(() {
      _countryName = countryName;
      _hospital = hospital;
    });
  }

  @override
  void initState() {
    super.initState();

    _setHospitalInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: _hospital != null ? Text("TeoG Swift - "+ _hospital.name +  ", " + _countryName) : Text("TeoG Swift"),
        actions: [
          Padding(padding: EdgeInsets.only(right: 20.0),
            child: TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? null : Colors.white;
                }),
              ),
              child: Text("Logout"),
              onPressed: () => _logout(context),
            )
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            Flexible(child: FractionallySizedBox(widthFactor: 0.8, heightFactor: 0.8, child: DoubleCardLayout(DoubleCardLayout.horizontal, SearchForm(), "OR", FilterForm()))),
          ]
        )
      ),
    );
  }
}

class SearchForm extends StatefulWidget {
  @override
  _SearchFormState createState() => _SearchFormState();
}

class _SearchFormState extends State with SessionMixin {
  final _formKey = GlobalKey<FormState>();

  final _deviceIDController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  ///Validates whether a given [value] is a valid device ID.
  ///
  ///Returns null if value is valid, otherwise text message.
  String? validateDeviceID(String? value) {
    if(value != null && value.isNotEmpty) {
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
      }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey,
      child: SizedBox(width: 300,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('By entering a barcode number', style: Theme
              .of(context)
              .textTheme
              .headline5),
          SizedBox(height: 10),
          Text("This is the easiest way. Please look for a barcode like this and enter the marked number:"),
          SizedBox(height: 5),
          Flexible(child: Image(image: AssetImage('graphics/barcode.jpg'))),
          TextFormField(
            controller: _deviceIDController,
            decoration: InputDecoration(hintText: 'Barcode Number'),
            keyboardType: TextInputType.number,
            autofocus: true,
            validator: (value) => validateDeviceID(value),
            onFieldSubmitted: (value) => _processDeviceId(),
          ),
          SizedBox(height: 10),
          ElevatedButton(
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

  final _scrollController = ScrollController();

  DepartmentFilter? _departmentFilter;
  List<PreviewDeviceInfo> _filteredDevices = [];
  bool _loading = false;

  void _processInput() {
    if (_formKey.currentState.validate()) {
      setState(() {
        _filteredDevices = [];
        _loading = true;
      });

      Comm.searchDevices(_typeController.text, _manufacturerController.text, filter: _departmentFilter).then((devices) {
        setState(() {
          _filteredDevices = devices;
          _loading = false;
        });
      }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        setState(() {
          _loading = false;
        });
      });
    }
  }

  void _openDeviceById(int id) {
    Comm.fetchDevice(id).then((deviceInfo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(deviceInfo: deviceInfo),
        )
      );
    }).onError<MessageException>((error, stackTrace) {
      final snackBar = SnackBar(content: Text(error.message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _filterDepartment() {
    showDialog<DepartmentFilter>(
      context: context,
      builder: (BuildContext context) {
        return OrganizationFilterView(orgUnit: _departmentFilter != null ? _departmentFilter!.parent : null);
      }
    ).then((departmentFilter) {
      setState(() {
        _departmentFilter = departmentFilter;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey,
      child: SizedBox(width: 450,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('By searching', style: Theme
              .of(context)
              .textTheme
              .headline5),
          SizedBox(height: 10),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              _departmentFilter != null ? Text("Department: " + _departmentFilter!.parent.name, style: TextStyle(fontSize: 25)) : Container(),
              _departmentFilter != null ? IconButton(
                iconSize: 25,
                icon: Icon(Icons.cancel_outlined, color: Colors.red[700]),
                tooltip: "clear selection",
                onPressed: () => setState(() => { _departmentFilter = null }), 
              ): Container(),
              OutlinedButton(onPressed: () => _filterDepartment(), child: Text("select department...")),
            ]
          ),
          TextFormField(
            controller: _typeController,
            decoration: InputDecoration(labelText: 'Device type (e.g. "Ventilator")'),
            autofocus: true,
            onFieldSubmitted: (value) => _processInput(),
          ),
          TextFormField(
            controller: _manufacturerController,
            decoration: InputDecoration(labelText: 'Manufacturer'),
            onFieldSubmitted: (value) => _processInput(),
          ),
          SizedBox(height: 10),
          _loading ? CircularProgressIndicator() : ElevatedButton(
            onPressed: () => _processInput(),
            child: Text('Search'),
          ),
          SizedBox(height: 10),
          Text(_filteredDevices.length.toString() + " device(s) match the filter:"),
          SizedBox(height: 10),
          Flexible(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(5),
              itemCount: _filteredDevices.length,
              itemBuilder: (BuildContext context, int index) {
                PreviewDeviceInfo deviceInfo = _filteredDevices[index];
                HospitalDevice device = deviceInfo.device;

                return ListTile(
                  leading: deviceInfo.imageData != null ? Image.memory(base64Decode(deviceInfo.imageData!)) : Text("no image"),
                  title: Text(device.type),
                  subtitle: Text(device.manufacturer + " " + device.model),
                  trailing: device.orgUnit != null ? Text(device.orgUnit!) : null,
                  onTap: () => _openDeviceById(device.id)
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
          )
        ],
      ),
    ));
  }
}