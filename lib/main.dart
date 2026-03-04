import 'package:flutter/material.dart';
import 'package:sssbuddy/Screen/Splash.dart';
import 'Screen/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Splash());
  }
}
