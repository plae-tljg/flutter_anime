import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';
import 'dart:io';
import '../entities/download_item.dart';
import '../../core/services/log_service.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final LogService _logger = LogService();
  final Map<String, DownloadItem> _downloads = {};
  final StreamController<Map<String, DownloadItem>> _controller =
      StreamController<Map<String, DownloadItem>>.broadcast();
  Dio? _dio;
  CookieJar? _cookieJar;
  final WebviewCookieManager _webviewCookieManager = WebviewCookieManager();

  Stream<Map<String, DownloadItem>> get downloadsStream => _controller.stream;
  Map<String, DownloadItem> get downloads => Map.unmodifiable(_downloads);

  Future<void> initialize() async {
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
      ..options.receiveTimeout = const Duration(minutes: 30)
      ..options.sendTimeout = const Duration(minutes: 30);

    _logger.info('DownloadManager initialized');
  }

  Future<DownloadItem> startDownload(
    String url,
    String title, {
    String? savePath,
  }) async {
    await initialize();

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = '${title}_$id.mp4';
    final path = savePath ?? fileName;

    final item = DownloadItem(
      id: id,
      title: title,
      url: url,
      savePath: path,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );

    _downloads[id] = item;
    _notifyListeners();

    _startDownloadTask(item);

    return item;
  }

  Future<void> _startDownloadTask(DownloadItem item) async {
    try {
      _logger.info('Starting download: ${item.title}');

      final cookieString = await _getWebViewCookies(item.url);

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Referer': item.url,
        'Cookie': cookieString,
        'Range': 'bytes=0-',
      };

      await _dio!.download(
        item.url,
        item.savePath,
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
            _downloads[item.id] = item.copyWith(
              progress: progress,
              receivedBytes: received,
              totalBytes: total,
            );
            _notifyListeners();
          }
        },
      );

      _downloads[item.id] = item.copyWith(
        progress: 1.0,
        status: DownloadStatus.completed,
        completedAt: DateTime.now(),
      );
      _logger.info('Download completed: ${item.title}');
    } catch (e, st) {
      _logger.error('Download failed: ${item.title}', e, st);
      _downloads[item.id] = item.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    }

    _notifyListeners();
  }

  Future<void> pauseDownload(String id) async {
    final item = _downloads[id];
    if (item != null) {
      _downloads[id] = item.copyWith(status: DownloadStatus.paused);
      _notifyListeners();
    }
  }

  Future<void> resumeDownload(String id) async {
    final item = _downloads[id];
    if (item != null) {
      _downloads[id] = item.copyWith(status: DownloadStatus.downloading);
      _notifyListeners();
      _startDownloadTask(item);
    }
  }

  Future<void> cancelDownload(String id) async {
    final item = _downloads[id];
    if (item != null) {
      try {
        final file = File(item.savePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _downloads.remove(id);
      _notifyListeners();
    }
  }

  Future<void> retryDownload(String id) async {
    final item = _downloads[id];
    if (item != null) {
      _downloads[id] = item.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.0,
        errorMessage: null,
      );
      _notifyListeners();
      _startDownloadTask(item);
    }
  }

  Future<String> _getWebViewCookies(String url) async {
    try {
      final cookies = await _webviewCookieManager.getCookies(url);
      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (e) {
      _logger.warning('Failed to get cookies: $e');
      return '';
    }
  }

  void _notifyListeners() {
    _controller.add(Map.from(_downloads));
  }

  void dispose() {
    _controller.close();
  }

  List<DownloadItem> get activeDownloads =>
      _downloads.values.where((d) => d.status == DownloadStatus.downloading).toList();

  List<DownloadItem> get completedDownloads =>
      _downloads.values.where((d) => d.status == DownloadStatus.completed).toList();

  List<DownloadItem> get failedDownloads =>
      _downloads.values.where((d) => d.status == DownloadStatus.failed).toList();
}