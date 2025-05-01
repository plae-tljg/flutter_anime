import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<Directory> getAppDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final usePublicDirectory =
        prefs.getBool('use_public_download_directory') ?? false;

    if (usePublicDirectory) {
      // 使用公共下载目录
      final publicDir = Directory('/storage/emulated/0/Download');
      if (!await publicDir.exists()) {
        await publicDir.create(recursive: true);
        debugPrint('创建公共下载目录: ${publicDir.path}');
      }
      return publicDir;
    } else {
      // 使用应用外部存储目录
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) {
        throw Exception('无法获取应用存储目录');
      }

      // 创建 Downloads 目录
      final downloadDir = Directory('${appDir.path}/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
        debugPrint('创建应用下载目录: ${downloadDir.path}');
      }
      return downloadDir;
    }
  }

  static Future<List<Directory>> getVideoDirectories() async {
    final List<Directory> directories = [];
    final prefs = await SharedPreferences.getInstance();
    final usePublicDirectory =
        prefs.getBool('use_public_download_directory') ?? false;

    if (usePublicDirectory) {
      // 添加公共下载目录
      final publicDir = Directory('/storage/emulated/0/Download');
      if (await publicDir.exists()) {
        directories.add(publicDir);
      }
    } else {
      // 添加应用外部存储目录
      try {
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final downloadDir = Directory('${appDir.path}/Downloads');
          if (await downloadDir.exists()) {
            directories.add(downloadDir);
          }
        }
      } catch (e) {
        debugPrint('获取应用下载目录失败: $e');
      }
    }

    return directories;
  }

  static Future<bool> ensureAppDirectories() async {
    try {
      await getAppDownloadDirectory();
      return true;
    } catch (e) {
      debugPrint('创建应用目录失败: $e');
      return false;
    }
  }

  // 获取应用包名
  static String getPackageName() {
    return 'com.example.anime_webview';
  }
}
