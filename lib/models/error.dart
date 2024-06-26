import 'package:flutter/material.dart';

class ErrorLogger {
  ErrorLogger._privateConstructor();
  static final ErrorLogger instance = ErrorLogger._privateConstructor();

  final List<String> _customLogs = [];
  final List<FlutterErrorDetails> _fluttererrorLogs = [];

  void logFlutterError(FlutterErrorDetails details) {
    _fluttererrorLogs.add(details);
  }

  void logCustomError(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _customLogs.add('$timestamp: $message');
  }

  List<String> get customLogs => _customLogs;
  List<FlutterErrorDetails> get errorLogs => _fluttererrorLogs;
}