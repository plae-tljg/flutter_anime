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
import '../../core/services/log_service.dart';

class AnimeService {
  final _logger = LogService();

  Future<List<Anime>> fetchAnimeList() async {
    try {
      _logger.info('开始获取动漫列表');
      final response = await http.get(Uri.parse(AppConfig.baseUrl));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final animeElements = document.querySelectorAll('ul li a');
        _logger.debug('成功获取到 ${animeElements.length} 个动漫条目');

        return animeElements.map((element) {
          return AnimeModel(
            id: element.attributes['href'] ?? '',
            title: element.text.trim(),
            url: element.attributes['href'] ?? '',
          );
        }).toList();
      } else {
        _logger.error('加载动漫列表失败: ${response.statusCode}');
        throw Exception('加载动漫列表失败');
      }
    } catch (e, stackTrace) {
      _logger.error('获取动漫列表时发生错误', e, stackTrace);
      rethrow;
    }
  }

  Future<String> extractVideoUrl(String animeUrl) async {
    _logger.info('开始提取视频URL: $animeUrl');
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(animeUrl));

    // 等待页面加载完成
    await Future.delayed(const Duration(seconds: 3));
    _logger.debug('WebView页面加载完成，开始提取视频URL');

    // 提取视频URL
    final videoUrl = await WebContentService.extractVideoUrl(controller);
    _logger.info('成功提取视频URL');
    return videoUrl;
  }

  Future<void> downloadVideo(
    String videoUrl,
    String fileName, {
    Function(double)? onProgress,
  }) async {
    try {
      _logger.info('开始下载视频: $fileName');

      // 请求所有必要的权限
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.notification,
      ];

      for (var permission in permissions) {
        final status = await permission.status;
        if (status.isDenied) {
          _logger.warning('请求权限: ${permission.toString()}');
          final result = await permission.request();
          if (!result.isGranted) {
            _logger.error('权限被拒绝: ${permission.toString()}');
            throw Exception('需要${permission.toString()}权限才能下载视频');
          }
        }
      }

      // 获取下载目录
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('无法获取下载目录');
      }

      if (!await downloadsDir.exists()) {
        _logger.debug('创建下载目录');
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');

      // 检查文件是否已存在
      if (await file.exists()) {
        _logger.warning('文件已存在: ${file.path}');
        throw Exception('文件已存在: ${file.path}');
      }

      // 下载文件
      _logger.debug('开始下载文件到: ${file.path}');
      await Dio().download(
        videoUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      _logger.info('文件下载完成: ${file.path}');
    } catch (e, stackTrace) {
      _logger.error('下载视频时发生错误', e, stackTrace);
      rethrow;
    }
  }
}
