import 'package:flutter/material.dart';

class MyCircularProgressIndicator extends StatefulWidget {
  MyCircularProgressIndicator({Key key, this.strokeWidth}) : super(key: key);
  final double strokeWidth;
  @override
  _MyCircularProgressIndicatorState createState() =>
      _MyCircularProgressIndicatorState();
}

class _MyCircularProgressIndicatorState
    extends State<MyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  Animation<Color> animation;
  AnimationController _controller;
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 250),
    );
  }

  void animateColor() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: widget.strokeWidth,
      valueColor:
          ColorTween(begin: Colors.red, end: Colors.blue).animate(_controller),
    );
  }
}
