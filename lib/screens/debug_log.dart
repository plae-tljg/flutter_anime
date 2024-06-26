import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/error.dart';


class ErrorLogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final errorLogs = ErrorLogger.instance.errorLogs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Error Logs'),
      ),
      body: ListView.builder(
        itemCount: errorLogs.length,
        itemBuilder: (context, index) {
          final error = errorLogs[index];
          return ListTile(
            title: Text('Error ${index + 1}'),
            subtitle: Text(error.exceptionAsString()),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text(error.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
