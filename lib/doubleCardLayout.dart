import 'package:flutter/material.dart';

class DoubleCardLayout extends StatelessWidget {
  static const int horizontal = 0;
  static const int vertical = 1;

  final int direction;
  final Widget leftView;
  final String betweenText;
  final Widget rightView;

  DoubleCardLayout(this.direction, this.leftView, this.betweenText, this.rightView);

  @override
  Widget build(BuildContext context) {
    if(direction == horizontal) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Card(child: Padding(
            padding: EdgeInsets.all(10.0),
            child: leftView)
          )),
          SizedBox(width: 10),
          Text(betweenText, style: TextStyle(fontSize: 30)),
          SizedBox(width: 10),
          Flexible(child: Card(child: Padding(
            padding: EdgeInsets.all(10.0),
            child: rightView)
          )),
      ]);
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Card(child: Padding(
            padding: EdgeInsets.all(10.0),
            child: leftView)
          )),
          SizedBox(height: 10),
          Text(betweenText, style: TextStyle(fontSize: 30)),
          SizedBox(height: 10),
          Flexible(child: Card(child: Padding(
            padding: EdgeInsets.all(10.0),
            child: rightView)
          )),
      ]);
    }
  }
}