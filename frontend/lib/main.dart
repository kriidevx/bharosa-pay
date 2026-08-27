import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Entry point of the Bharosa Pay app.
void main() {
  runApp(const BharosaPayApp());
}

/// Root widget of the application.
///
/// This sets up the MaterialApp and points it at HomeScreen as the
/// first screen the user sees. No scanner, API, or payment logic here —
/// this file only wires up the app shell.
class BharosaPayApp extends StatelessWidget {
  const BharosaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bharosa Pay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}