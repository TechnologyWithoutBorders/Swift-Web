import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:teog_swift/utilities/constants.dart';

class AboutScreen extends StatefulWidget {
  static const String route = '/about';

  AboutScreen({Key key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );


  @override
  void initState() {
    super.initState();
    
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("About " + _packageInfo.appName),
        backgroundColor: Color(Constants.teog_blue),
      ),
      body: Center(child: Text(_packageInfo.appName + " v" + _packageInfo.version + "-" + _packageInfo.buildNumber))
    );
  }
}
