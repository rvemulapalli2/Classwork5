import 'package:flutter/material.dart';
import 'aquarium_screen.dart'; // Import the aquarium screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquarium App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(), // Set AquariumScreen as the home screen
    );
  }
}
