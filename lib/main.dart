import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'core/services/log_service.dart';
import 'presentation/screens/home/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> _initializeSettings() async {
  final prefs = await SharedPreferences.getInstance();

  // 初始化默认视频模式设置
  if (!prefs.containsKey('default_video_only_mode')) {
    await prefs.setBool('default_video_only_mode', true);
  }

  // 初始化默认下载目录设置
  if (!prefs.containsKey('use_public_download_directory')) {
    await prefs.setBool('use_public_download_directory', false);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务
  final logger = LogService();
  logger.info('应用启动');

  // 初始化默认设置
  await _initializeSettings();

  // 测试所有路径
  await testAllPaths();

  setupDependencies();
  runApp(const MyApp());
}

Future<void> testAllPaths() async {
  debugPrint('\n=== 测试所有存储路径 ===');

  try {
    // 应用文档目录
    final appDocDir = await getApplicationDocumentsDirectory();
    debugPrint('应用文档目录: ${appDocDir.path}');
  } catch (e) {
    debugPrint('获取应用文档目录失败: $e');
  }

  try {
    // 应用支持目录
    final appSupportDir = await getApplicationSupportDirectory();
    debugPrint('应用支持目录: ${appSupportDir.path}');
  } catch (e) {
    debugPrint('获取应用支持目录失败: $e');
  }

  try {
    // 临时目录
    final tempDir = await getTemporaryDirectory();
    debugPrint('临时目录: ${tempDir.path}');
  } catch (e) {
    debugPrint('获取临时目录失败: $e');
  }

  try {
    // 外部存储目录
    final externalDir = await getExternalStorageDirectory();
    debugPrint('外部存储目录: ${externalDir?.path}');
  } catch (e) {
    debugPrint('获取外部存储目录失败: $e');
  }

  try {
    // 下载目录
    final downloadsDir = await getDownloadsDirectory();
    debugPrint('下载目录: ${downloadsDir?.path}');
  } catch (e) {
    debugPrint('获取下载目录失败: $e');
  }

  // 测试一些固定路径
  debugPrint('\n=== 测试固定路径 ===');
  debugPrint('公共下载目录: /storage/emulated/0/Download');
  debugPrint('Android数据目录: /data/user/0/com.example.anime_webview');
  debugPrint(
      'Android外部存储目录: /storage/emulated/0/Android/data/com.example.anime_webview');

  debugPrint('\n=== 测试目录权限 ===');
  try {
    final testDir = Directory(
        '/storage/emulated/0/Android/data/com.example.anime_webview/test');
    await testDir.create(recursive: true);
    debugPrint('可以创建目录: ${testDir.path}');
    await testDir.delete();
    debugPrint('可以删除目录: ${testDir.path}');
  } catch (e) {
    debugPrint('测试目录权限失败: $e');
  }

  debugPrint('\n=== 测试完成 ===\n');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '动漫应用',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
