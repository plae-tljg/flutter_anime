import 'package:flutter/material.dart';
import 'info_screen.dart';
import 'debug_log.dart';
import 'video_screen.dart';
import 'video_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _navigateToInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InfoScreen()),
    );
  }

  void _navigateToVideoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.error),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ErrorLogPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _navigateToInfoPage,
              child: Text('Go to Info Page'),
            ),
            ElevatedButton(
              onPressed: _navigateToVideoPage,
              child: Text('Go to Video Page'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}