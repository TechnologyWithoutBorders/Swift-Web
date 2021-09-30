import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  static const String route = '/about';

  AboutScreen({Key key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center()
    );
  }
}
