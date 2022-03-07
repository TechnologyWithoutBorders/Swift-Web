import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:teog_swift/utilities/marketplaceDeviceInfo.dart';
import 'package:teog_swift/utilities/messageException.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/hospitalDevice.dart';

class MarketplaceScreen extends StatefulWidget {
  MarketplaceScreen({Key key}) : super(key: key);

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _typeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _distanceController = TextEditingController();

  final _scrollController = ScrollController();

  List<MarketplaceDeviceInfo> _filteredDevices = [];
  bool _loading = false;

  void _processInput() {
    if (_formKey.currentState.validate()) {
      setState(() {
        _filteredDevices = [];
        _loading = true;
      });

      Comm.searchMarketplaceDevices(_typeController.text, _manufacturerController.text, int.parse(_distanceController.text)).then((devices) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Marketplace"),
      ),
      body: Center(child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("This feature is experimental and will be subject to changes.", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Expanded(child: 
                Form(
                  key: _formKey,
                  child: SizedBox(width: 450,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Search for devices in your area:', style: Theme
                          .of(context)
                          .textTheme
                          .headline5),
                      SizedBox(height: 10),
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
                      TextFormField(
                        controller: _distanceController,
                        decoration: InputDecoration(labelText: 'within distance [km]'),
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
                            MarketplaceDeviceInfo deviceInfo = _filteredDevices[index];
                            HospitalDevice device = deviceInfo.device;

                            return ListTile(
                              leading: deviceInfo.imageData.isNotEmpty ? Image.memory(base64Decode(deviceInfo.imageData)) : Text("no image"),
                              title: Text(device.type),
                              subtitle: Text(device.manufacturer + " " + device.model),
                              trailing: Text(deviceInfo.location + "\n" + deviceInfo.distance.toString() + " km")
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) => const Divider(),
                        ),
                      )
                    ],
                  ),
                )))
              ]
            )
          ),
        )
      ))
    );
  }
}