import 'package:flutter/material.dart';
import '../models/error.dart';

class ErrorLogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final customLogs = ErrorLogger.instance.customLogs;
    final flutterErrorLogs = ErrorLogger.instance.errorLogs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Error Logs'),
      ),
      body: customLogs.isEmpty && flutterErrorLogs.isEmpty
          ? Center(child: Text('No error logs available.'))
          : ListView(
              children: [
                if (customLogs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Custom Logs',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...customLogs.map((log) => ListTile(
                        title: Text(log),
                      )),
                ],
                if (flutterErrorLogs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Flutter Error Logs',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...flutterErrorLogs.map((log) => ListTile(
                        title: Text(log.exceptionAsString()),
                        subtitle: Text(log.stack.toString()),
                      )),
                ],
              ],
            ),
    );
  }
}
