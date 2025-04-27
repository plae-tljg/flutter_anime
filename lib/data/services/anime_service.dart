import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/config/app_config.dart';
import '../../domain/entities/anime.dart';
import '../models/anime_model.dart';
import 'web_content_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class AnimeService {
  Future<List<Anime>> fetchAnimeList() async {
    try {
      final response = await http.get(Uri.parse(AppConfig.baseUrl));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final animeElements = document.querySelectorAll('ul li a');

        return animeElements.map((element) {
          return AnimeModel(
            id: element.attributes['href'] ?? '',
            title: element.text.trim(),
            url: element.attributes['href'] ?? '',
          );
        }).toList();
      } else {
        throw Exception('加载动漫列表失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> extractVideoUrl(String animeUrl) async {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(animeUrl));

    // 等待页面加载完成
    await Future.delayed(const Duration(seconds: 3));

    // 提取视频URL
    return await WebContentService.extractVideoUrl(controller);
  }

  Future<void> downloadVideo(
    String videoUrl,
    String fileName, {
    Function(double)? onProgress,
  }) async {
    try {
      // 检查存储权限
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          throw Exception('需要存储权限才能下载视频');
        }
      }

      // 获取 Downloads 目录
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');

      // 检查文件是否已存在
      if (await file.exists()) {
        throw Exception('文件已存在: ${file.path}');
      }

      // 下载文件
      await Dio().download(
        videoUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      print('文件已下载到: ${file.path}');
    } catch (e) {
      print('下载失败: $e');
      rethrow;
    }
  }
}
