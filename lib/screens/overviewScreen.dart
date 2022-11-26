import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:teog_swift/main.dart';
import 'package:teog_swift/screens/organizationFilterView.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/previewDeviceInfo.dart';
import 'package:teog_swift/screens/deviceInfoScreen.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;

import 'package:teog_swift/utilities/sessionMixin.dart';
import 'package:teog_swift/utilities/messageException.dart';

import 'package:teog_swift/utilities/preferenceManager.dart' as Prefs;
import 'package:teog_swift/utilities/hospital.dart';

class OverviewScreen extends StatefulWidget {
  static const String route = '/reporting';

  const OverviewScreen({Key? key}) : super(key: key);

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String? _countryName;
  Hospital? _hospital;

  void _logout(BuildContext context) async {
    await Prefs.logout();
    Navigator.pushNamedAndRemoveUntil(context, SwiftApp.route, (r) => false);
  }

  void _setHospitalInfo() async {
    String? countryName = await Prefs.getCountry();
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
        title: _hospital != null && _countryName != null ? Text("TeoG Swift - ${_hospital!.name}, ${_countryName!}") : const Text("TeoG Swift"),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 20.0),
            child: TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled) ? Colors.grey : Colors.white;
                }),
              ),
              child: const Text("Logout"),
              onPressed: () => _logout(context),
            )
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(20.0), child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome', style: Theme
                .of(context)
                .textTheme
                .headline4),
              Text('Please tell us which device you are looking for', style: Theme
                .of(context)
                .textTheme
                .headline5),
              const SizedBox(height: 25),
              Card(child: Padding(padding: const EdgeInsets.all(10.0), child: SearchForm())),
              const SizedBox(height: 5),
              const Text("OR", style: TextStyle(fontSize: 30)),
              const SizedBox(height: 5),
              Card(child: Padding(padding: const EdgeInsets.all(10.0), child: FilterForm())),
            ]
          )
        )
      ),
    ));
  }
}

class SearchForm extends StatefulWidget {
  const SearchForm({Key? key}) : super(key: key);

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
    if (_formKey.currentState!.validate()) {
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
          const SizedBox(height: 10),
          const Text("This is the easiest way. Please look for a barcode like this and enter the marked number:"),
          const SizedBox(height: 5),
          const Flexible(child: Image(image: AssetImage('graphics/barcode.jpg'))),
          TextFormField(
            controller: _deviceIDController,
            decoration: const InputDecoration(hintText: 'Barcode Number'),
            keyboardType: TextInputType.number,
            autofocus: true,
            validator: (value) => validateDeviceID(value),
            onFieldSubmitted: (value) => _processDeviceId(),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _processDeviceId(),
            child: const Text('Search'),
          ),
        ],
      ),
    ));
  }
}

class FilterForm extends StatefulWidget {
  const FilterForm({Key? key}) : super(key: key);

  @override
  _FilterFormState createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  final _formKey = GlobalKey<FormState>();

  final _typeController = TextEditingController();
  final _manufacturerController = TextEditingController();

  final _scrollController = ScrollController();

  OrganizationalInfo? _orgInfo;
  OrganizationalUnit? _department;
  List<PreviewDeviceInfo> _filteredDevices = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    Comm.getOrganizationalInfo().then((orgInfo) {
      setState(() {
        orgInfo.units.sort((a, b) => a.name.compareTo(b.name));

        _orgInfo = orgInfo;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _processInput() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _filteredDevices = [];
        _loading = true;
      });

      DepartmentFilter? filter;

      if(_department != null) {
        filter = DepartmentFilter(_department!, []);
      } else {
        filter = null;
      }

      Comm.searchDevices(_typeController.text, _manufacturerController.text, filter: filter).then((devices) {
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

  @override
  Widget build(BuildContext context) {
    return Form(key: _formKey,
      child: SizedBox(width: 450, height: 600,//TODO: loading animation
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('By searching', style: Theme
              .of(context)
              .textTheme
              .headline5),
          const SizedBox(height: 10),
          DropdownButton<OrganizationalUnit>(
            hint: const Text("Department"),
            value: _department,
            onChanged: (OrganizationalUnit? unit) {
              setState(() {
                _department = unit;
              });
            },
            items: _orgInfo?.units.map<DropdownMenuItem<OrganizationalUnit>>((OrganizationalUnit unit) {
              return DropdownMenuItem<OrganizationalUnit>(
                value: unit,
                child: Text(unit.name),
              );
            }).toList(),
          ),
          TextFormField(
            controller: _typeController,
            decoration: const InputDecoration(labelText: 'Device type (e.g. "Ventilator")'),
            autofocus: true,
            onFieldSubmitted: (value) => _processInput(),
          ),
          TextFormField(
            controller: _manufacturerController,
            decoration: const InputDecoration(labelText: 'Manufacturer'),
            onFieldSubmitted: (value) => _processInput(),
          ),
          const SizedBox(height: 10),
          _loading ? const CircularProgressIndicator() : ElevatedButton(
            onPressed: () => _processInput(),
            child: const Text('Search'),
          ),
          const SizedBox(height: 10),
          Text("${_filteredDevices.length} device(s) match the filter:"),
          const SizedBox(height: 10),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              controller: _scrollController,
              padding: const EdgeInsets.all(5),
              itemCount: _filteredDevices.length,
              itemBuilder: (BuildContext context, int index) {
                PreviewDeviceInfo deviceInfo = _filteredDevices[index];
                HospitalDevice device = deviceInfo.device;

                return ListTile(
                  leading: deviceInfo.imageData != null && deviceInfo.imageData!.isNotEmpty ? Image.memory(base64Decode(deviceInfo.imageData!)) : const Text("no image"),
                  title: Text(device.type),
                  subtitle: Text("${device.manufacturer} ${device.model}"),
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