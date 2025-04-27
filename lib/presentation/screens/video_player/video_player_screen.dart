import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/web_content_service.dart';
import '../../../core/di/service_locator.dart';
import '../../providers/anime_provider.dart';
import '../../../core/debug/webview_debug_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String animeUrl;
  final String title;

  const VideoPlayerScreen({
    Key? key,
    required this.animeUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  late final AnimeProvider _provider;
  bool _isLoading = true;
  String? _error;
  bool _isVideoReady = false;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _provider = getIt<AnimeProvider>();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                print('页面开始加载: $url');
                setState(() => _isLoading = true);
              },
              onPageFinished: (String url) async {
                print('页面加载完成: $url');
                try {
                  // 设置调试
                  WebViewDebugService.setupDebugChannels(_controller);
                  await WebViewDebugService.injectDebugScripts(_controller);

                  // 检查视频元素
                  await WebViewDebugService.inspectVideoElement(_controller);

                  await WebContentService.isolateVideoElement(_controller);
                  print('视频元素隔离完成');
                  setState(() {
                    _isLoading = false;
                    _isVideoReady = true;
                  });
                } catch (e) {
                  print('视频处理错误: $e');
                  setState(() {
                    _error = e.toString();
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                print('Web资源错误: ${error.description}');
                setState(() {
                  _error = error.description;
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.animeUrl));
  }

  Future<void> _downloadVideo() async {
    if (!_isVideoReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请等待视频加载完成')));
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final videoUrl = await WebContentService.extractVideoUrl(_controller);
      if (videoUrl.isEmpty) {
        throw Exception('无法获取视频URL');
      }

      await _provider.downloadVideo(
        videoUrl,
        '${widget.title}.mp4',
        context,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('下载成功')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          if (_isVideoReady)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: (_isLoading || _isDownloading) ? null : _downloadVideo,
              tooltip: _isDownloading ? '正在下载...' : '下载视频',
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isLoading || _isDownloading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isDownloading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(value: _downloadProgress),
                          const SizedBox(height: 8),
                          Text(
                            '下载进度: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          ),
                        ],
                      ),
                    )
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                  _isVideoReady = false;
                });
                _initializeWebView();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return WebViewWidget(controller: _controller);
  }
}
