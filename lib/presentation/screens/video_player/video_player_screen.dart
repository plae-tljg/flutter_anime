import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/log_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../domain/services/download_manager.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  final LogService _logger = LogService();
  bool _isLoading = true;
  bool _isVideoOnlyMode = true;
  bool _isDownloading = false;
  bool _isFirstLoad = true;
  bool _isLoadingFinalUrl = false;
  double _downloadProgress = 0.0;
  String? _currentDownloadPath;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 URL 发生变化，重新初始化 WebView
    if (oldWidget.videoUrl != widget.videoUrl) {
      _resetAndInitialize();
    }
  }

  Future<void> _resetAndInitialize() async {
    setState(() {
      _isLoading = true;
      _isFirstLoad = true;
      _isLoadingFinalUrl = false;
      _isVideoOnlyMode = true;
    });

    // 清除之前的 WebView 状态
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    await _controller.runJavaScript('window.location.reload()');

    // 重新初始化
    _initializeWebView();
  }

  Future<void> _loadDefaultMode() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultMode = prefs.getBool('default_video_only_mode') ?? true;
    if (defaultMode) {
      setState(() {
        _isVideoOnlyMode = true;
      });
    }
  }

  Future<void> _applyVideoOnlyMode() async {
    try {
      _isLoadingFinalUrl = true;
      setState(() {});

      await Future.delayed(const Duration(seconds: 2));

      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          const poster = document.querySelector('.vjs-poster');
          const playBtn = document.querySelector('.vjs-big-play-button');
          if (poster) poster.click();
          else if (playBtn) playBtn.click();
          return 'clicked';
        })();
      ''');

      await Future.delayed(const Duration(seconds: 1));

      final videoResult = await _controller.runJavaScriptReturningResult('''
        (function() {
          const video = document.querySelector('video');
          if (video) return video.src || video.currentSrc || '';
          const videos = document.querySelectorAll('video');
          for (let v of videos) {
            if (v.src) return v.src;
          }
          return '';
        })();
      ''');

      final videoUrl = videoResult.toString().replaceAll('"', '');

      if (videoUrl.isNotEmpty && videoUrl.startsWith('http')) {
        _logger.info('Direct video URL found: $videoUrl');
        await _controller.loadRequest(Uri.parse(videoUrl));
        await Future.delayed(const Duration(seconds: 1));
        await _cleanupPage();
      } else {
        _logger.info('No direct video URL, keeping embedded player');
        await _cleanupPage();
      }
    } catch (e) {
      _logger.error('Video mode error', e, StackTrace.current);
      await _cleanupPage();
    } finally {
      _isLoadingFinalUrl = false;
      setState(() {});
    }
  }

  Future<void> _cleanupPage() async {
    try {
      await _controller.runJavaScript('''
        (function() {
          document.body.style.overflow = 'hidden';
          const header = document.querySelector('header');
          const footer = document.querySelector('footer');
          const sidebar = document.querySelector('.sidebar');
          if (header) header.style.display = 'none';
          if (footer) footer.style.display = 'none';
          if (sidebar) sidebar.style.display = 'none';
        })();
      ''');
    } catch (_) {}
  }

  Future<void> _toggleVideoOnlyMode() async {
    setState(() {
      _isVideoOnlyMode = !_isVideoOnlyMode;
    });

    if (_isVideoOnlyMode) {
      await _applyVideoOnlyMode();
    } else {
      // 退出视频模式时重新加载原始页面
      await _controller.loadRequest(Uri.parse(widget.videoUrl));
    }
  }

  Future<void> _initializeWebView() async {
    // 先加载默认模式设置
    await _loadDefaultMode();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            LogService().info('页面开始加载: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            LogService().info('页面加载完成: $url');

            // 只在第一次加载完成时应用默认视频模式
            if (_isFirstLoad && _isVideoOnlyMode) {
              _isFirstLoad = false;
              await _applyVideoOnlyMode();
            }

            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            _logger.info('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _logger.error('WebView error: ${error.description}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('加载失败: ${error.description}'),
                  action: SnackBarAction(
                    label: '重试',
                    onPressed: () => _resetAndInitialize(),
                  ),
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.videoUrl));
  }

  Future<void> _downloadVideo() async {
    if (_isDownloading) {
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
      });

      final directory = await StorageService.getAppDownloadDirectory();
      final filePath = '${directory.path}/${widget.title}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final file = File(filePath);
      if (await file.exists()) {
        throw Exception('File already exists');
      }

      String videoUrl = await _controller.currentUrl() ?? widget.videoUrl;

      if (!videoUrl.endsWith('.mp4')) {
        final result = await _controller.runJavaScriptReturningResult('''
          (function() {
            const video = document.querySelector('video');
            return video ? (video.src || video.currentSrc || '') : '';
          })();
        ''');
        videoUrl = result.toString().replaceAll('"', '');
        if (videoUrl.isEmpty) {
          throw Exception('Could not get video URL');
        }
      }

      await DownloadManager().startDownload(
        videoUrl,
        widget.title,
        savePath: filePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started, check Downloads tab for progress')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadVideo,
            tooltip: _isDownloading ? '正在下载...' : '下载视频',
          ),
          IconButton(
            icon: Icon(
                _isVideoOnlyMode ? Icons.fullscreen : Icons.fullscreen_exit),
            onPressed: _toggleVideoOnlyMode,
            tooltip: _isVideoOnlyMode ? '退出视频模式' : '仅显示视频',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isLoadingFinalUrl) WebViewWidget(controller: _controller),
          if (_isLoading || _isLoadingFinalUrl)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
