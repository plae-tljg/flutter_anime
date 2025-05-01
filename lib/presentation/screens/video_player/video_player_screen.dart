import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/web_content_service.dart';
import '../../../data/services/cookie_service.dart';
import '../../../core/services/log_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../../core/services/storage_service.dart';

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
  bool _isLoading = true;
  bool _isVideoOnlyMode = true;
  bool _isDownloading = false;
  bool _isFirstLoad = true;
  bool _isLoadingFinalUrl = false;
  double _downloadProgress = 0.0;
  StreamSubscription<double>? _progressSubscription;
  String? _currentDownloadPath;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
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

      // 1. 先隔离视频元素
      await WebContentService.isolateVideoElement(_controller);

      // 2. 模拟点击行为以获取真实MP4 URL
      final videoUrl =
          await WebContentService.getVideoUrlAfterClick(_controller);

      // 3. 如果成功获取到视频URL，使用该URL重新加载视频
      if (videoUrl.isNotEmpty) {
        await _controller.loadRequest(Uri.parse(videoUrl));
        // 重新应用视频隔离以确保只显示视频元素
        await WebContentService.isolateVideoElement(_controller);
        // 禁用自动播放
        await WebContentService.disableVideoAutoplay(_controller);
      } else {
        debugPrint('无法获取视频URL，保持当前状态');
      }
    } catch (e) {
      debugPrint('应用视频模式失败: $e');
      // 发生错误时回退到原始页面
      await _controller.loadRequest(Uri.parse(widget.videoUrl));
    } finally {
      _isLoadingFinalUrl = false;
      setState(() {});
    }
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
            LogService().info('导航请求: ${request.url}');
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            LogService().error('WebView错误: ${error.description}');
            // 如果发生错误，显示错误提示
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
      debugPrint('开始下载视频...');
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      // 获取下载目录设置
      final prefs = await SharedPreferences.getInstance();
      final usePublicDirectory =
          prefs.getBool('use_public_download_directory') ?? false;

      // 只有在使用公共下载目录时才请求存储权限
      if (usePublicDirectory && Platform.isAndroid) {
        debugPrint('使用公共下载目录，请求存储权限...');
        if (!await Permission.storage.request().isGranted) {
          throw Exception('需要存储权限才能下载到公共目录');
        }
      }

      // 获取下载目录
      final directory = await StorageService.getAppDownloadDirectory();
      debugPrint('最终使用的下载目录: ${directory.path}');

      // 生成文件名
      final fileName =
          '${widget.title}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${directory.path}/$fileName';
      debugPrint('完整文件路径: $filePath');

      // 检查文件是否已存在
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('文件已存在: $filePath');
        throw Exception('文件已存在，请勿重复下载');
      }

      // 检查是否正在下载同一个动漫
      if (_currentDownloadPath != null &&
          _currentDownloadPath!.contains(widget.title)) {
        debugPrint('正在下载相同的动漫: ${widget.title}');
        throw Exception('正在下载该动漫，请等待完成');
      }

      _currentDownloadPath = filePath;
      debugPrint('开始下载到路径: $filePath');

      // 获取当前页面URL
      String videoUrl = await _controller.currentUrl() ?? widget.videoUrl;
      debugPrint('视频URL: $videoUrl');

      // 如果当前URL不是直接的视频URL，尝试获取视频URL
      if (!videoUrl.endsWith('.mp4')) {
        debugPrint('尝试获取直接视频URL...');
        videoUrl = await WebContentService.getVideoUrlAfterClick(_controller);
        if (videoUrl.isEmpty) {
          debugPrint('无法获取视频URL');
          throw Exception('无法获取视频URL');
        }
        debugPrint('获取到视频URL: $videoUrl');
      }

      // 使用 CookieService 下载文件
      debugPrint('开始下载文件...');
      await CookieService.downloadFile(videoUrl, filePath);
      debugPrint('文件下载完成: $filePath');

      // 验证文件是否真的下载成功
      if (await file.exists()) {
        final fileSize = await file.length();
        debugPrint('文件下载成功，大小: ${fileSize} 字节');
      } else {
        debugPrint('警告：文件似乎没有成功下载');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('视频已下载到: $filePath')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('下载过程中发生错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _currentDownloadPath = null;
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
          if (_isDownloading)
            Positioned(
              right: 16,
              bottom: 16,
              child: StreamBuilder<double>(
                stream: CookieService.progressStream,
                initialData: 0.0,
                builder: (context, snapshot) {
                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.download),
                              const SizedBox(width: 8),
                              Text(
                                  '${(snapshot.data! * 100).toStringAsFixed(1)}%'),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _isDownloading = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: snapshot.data,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
