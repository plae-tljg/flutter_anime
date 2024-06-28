import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
// Make sure to import your error log page
import 'models/error.dart'; // Make sure to import your error logger

void main() {
    FlutterError.onError = (FlutterErrorDetails details) {
     FlutterError.dumpErrorToConsole(details);
     ErrorLogger.instance.logFlutterError(details);
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: 'Flutter Demo Home Page'),
    );
  }
}