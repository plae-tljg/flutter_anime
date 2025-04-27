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
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(animeUrl));

    // 等待页面加载完成
    await Future.delayed(const Duration(seconds: 3));

    // 提取视频URL
    return await WebContentService.extractVideoUrl(controller);
  }

  Future<void> downloadVideo(String videoUrl, String fileName) async {
    try {
      // 检查存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('需要存储权限才能下载视频');
      }

      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('下载失败: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
