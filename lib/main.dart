import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'core/services/log_service.dart';
import 'presentation/screens/home/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> _initializeSettings() async {
  final prefs = await SharedPreferences.getInstance();

  if (!prefs.containsKey('default_video_only_mode')) {
    await prefs.setBool('default_video_only_mode', true);
  }

  if (!prefs.containsKey('use_public_download_directory')) {
    await prefs.setBool('use_public_download_directory', false);
  }
}

Future<void> testAllPaths() async {
  debugPrint('\n=== Testing all storage paths ===');

  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    debugPrint('App documents: ${appDocDir.path}');
  } catch (e) {
    debugPrint('Failed to get app documents: $e');
  }

  try {
    final appSupportDir = await getApplicationSupportDirectory();
    debugPrint('App support: ${appSupportDir.path}');
  } catch (e) {
    debugPrint('Failed to get app support: $e');
  }

  try {
    final tempDir = await getTemporaryDirectory();
    debugPrint('Temp: ${tempDir.path}');
  } catch (e) {
    debugPrint('Failed to get temp: $e');
  }

  try {
    final externalDir = await getExternalStorageDirectory();
    debugPrint('External: ${externalDir?.path}');
  } catch (e) {
    debugPrint('Failed to get external: $e');
  }

  try {
    final downloadsDir = await getDownloadsDirectory();
    debugPrint('Downloads: ${downloadsDir?.path}');
  } catch (e) {
    debugPrint('Failed to get downloads: $e');
  }

  debugPrint('\n=== Path test complete ===\n');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = LogService();
  logger.info('App starting');

  await _initializeSettings();
  await testAllPaths();

  setupDependencies();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Webview',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}