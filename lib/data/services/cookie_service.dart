import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';

class CookieService {
  static Dio? _dio;
  static CookieJar? _cookieJar;
  static final WebviewCookieManager _webviewCookieManager =
      WebviewCookieManager();
  static final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  static Stream<double> get progressStream => _progressController.stream;

  static Future<void> initialize() async {
    if (_dio != null) return;

    final directory = await getApplicationDocumentsDirectory();
    final cookiePath = '${directory.path}/.cookies/';

    _cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookiePath),
    );

    _dio = Dio()
      ..interceptors.add(CookieManager(_cookieJar!))
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.sendTimeout = const Duration(seconds: 30);
  }

  static Future<String> _getWebViewCookies(String url) async {
    try {
      final cookies = await _webviewCookieManager.getCookies(url);
      debugPrint('=== WebView Cookie详情 ===');
      debugPrint('URL: $url');
      debugPrint('Cookie列表:');
      for (var cookie in cookies) {
        debugPrint('  ${cookie.name}: ${cookie.value}');
      }
      debugPrint('================');

      return cookies
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');
    } catch (e) {
      debugPrint('获取WebView Cookie失败: $e');
      return '';
    }
  }

  static Future<Response> downloadFile(
    String url,
    String savePath, {
    void Function(double)? onProgress,
  }) async {
    if (_dio == null) {
      await initialize();
    }

    try {
      debugPrint('开始下载文件...');
      debugPrint('URL: $url');
      debugPrint('保存路径: $savePath');

      // 从WebView获取cookies
      final cookieString = await _getWebViewCookies(url);

      // 记录详细的请求信息
      debugPrint('=== 请求详情 ===');
      debugPrint('请求URL: $url');
      debugPrint('请求方法: GET');
      debugPrint('Cookie: $cookieString');

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Sec-Fetch-Dest': 'video',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'same-origin',
        'Referer': url,
        'Cookie': cookieString,
        'Range': 'bytes=0-',
      };

      debugPrint('请求头:');
      headers.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      debugPrint('================');

      final response = await _dio!.download(
        url,
        savePath,
        options: Options(
          headers: headers,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 30),
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            debugPrint('下载进度: ${(progress * 100).toStringAsFixed(1)}%');
            _progressController.add(progress);
            onProgress?.call(progress);
          }
        },
      );

      return response;
    } catch (e) {
      _progressController.add(0.0);
      rethrow;
    }
  }

  static void dispose() {
    _progressController.close();
  }

  static Future<List<Cookie>> getCookies(String url) async {
    if (_cookieJar == null) {
      await initialize();
    }
    final cookies = await _cookieJar!.loadForRequest(Uri.parse(url));
    debugPrint('=== Cookie详情 ===');
    debugPrint('URL: $url');
    debugPrint('Cookie列表:');
    for (var cookie in cookies) {
      debugPrint('  ${cookie.name}: ${cookie.value}');
    }
    debugPrint('================');
    return cookies;
  }
}
