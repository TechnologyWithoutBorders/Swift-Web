import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/shortDeviceInfo.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/deviceState.dart';

class MarketplaceScreen extends StatefulWidget {
  MarketplaceScreen({Key key}) : super(key: key);

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
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
                
              ]
            )
          ),
        )
      ))
    );
  }
}