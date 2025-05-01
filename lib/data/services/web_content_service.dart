import 'package:webview_flutter/webview_flutter.dart';
import '../../core/debug/webview_debug_service.dart';

class WebContentService {
  static const String _videoSelector = 'video.vjs-tech';
  static const String _videoContainerSelector = '.vjscontainer';

  static Future<void> clickVideoPoster(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        const poster = document.querySelector('.vjs-poster');
        if (poster) {
          poster.click();
        }
      })();
    ''');
  }

  static Future<String> extractVideoUrl(WebViewController controller) async {
    try {
      final cssSelector = await extractCssSelector(controller);
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          let srcElement = document.querySelector('${cssSelector}_html5_api');
          let srcUrl = '';
          if (srcElement) {
            srcUrl = srcElement.src;
            console.log('找到视频URL:', srcUrl);
          }
          return srcUrl;
        })();
      ''');

      final url = result.toString().replaceAll('"', '');
      if (url.isEmpty) {
        throw Exception('无法找到视频元素');
      }
      return url;
    } catch (e) {
      print('提取视频URL失败: $e');
      throw Exception('提取视频URL失败: $e');
    }
  }

  static Future<String> getVideoUrlAfterClick(
      WebViewController controller) async {
    try {
      // 先点击视频海报
      await clickVideoPoster(controller);

      // 等待视频URL加载
      await Future.delayed(const Duration(seconds: 1));

      // 获取视频URL
      return await extractVideoUrl(controller);
    } catch (e) {
      print('获取视频URL失败: $e');
      throw Exception('获取视频URL失败: $e');
    }
  }

  static Future<void> disableVideoAutoplay(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        const video = document.querySelector('video');
        if (video) {
          video.autoplay = false;
          video.pause();
        }
      })();
    ''');
  }

  static Future<void> isolateVideoElement(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        // 选择要保留的元素
        const targetElement = document.querySelector('$_videoContainerSelector');

        if (targetElement) {
          // 移除所有其他元素
          const allElements = document.body.children;
          for (let i = allElements.length - 1; i >= 0; i--) {
            const element = allElements[i];
            if (element !== targetElement) {
              element.remove();
            }
          }
          
          // 将目标元素直接移动到body
          document.body.appendChild(targetElement);
          
          // 设置基本样式
          document.body.style.margin = '0';
          document.body.style.padding = '0';
          document.body.style.backgroundColor = '#000';
          document.body.style.display = 'block';
          
          // 设置视频容器样式
          targetElement.style.width = '100%';
          targetElement.style.height = '100vh';
          
          // 设置视频元素样式
          const video = targetElement.querySelector('video');
          if (video) {
            video.style.width = '100%';
            video.style.height = '100%';
            video.controls = true;
            video.playsInline = true;
            video.autoplay = false;
          }
        } else {
          console.log("未找到视频容器元素");
        }
      })();
    ''');
  }

  static Future<String> extractCssSelector(WebViewController controller) async {
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        function getCssSelector(element) {
          if (!element) return 'Element not found';
          var path = [];
          while (element.nodeType === Node.ELEMENT_NODE) {
            var selector = '';
            if (element.id) {
              selector += '#' + element.id;
              path.unshift(selector);
              break;
            } else {
              var sib = element, nth = 1;
              while (sib = sib.previousElementSibling) {
                if (sib.nodeName.toLowerCase() == selector)
                  nth++;
              }
              if (nth != 1)
                selector += ":nth-of-type(" + nth + ")";
            }
            path.unshift(selector);
            element = element.parentNode;
          }
          return path.join(" > ");
        }

        var parentElement = document.querySelector('$_videoContainerSelector');
        var childElement = parentElement ? parentElement.children[0] : null;

        return getCssSelector(childElement);
      })();
    ''');

    return result.toString().replaceAll('"', '');
  }

  static Future<void> captureVideoStream(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        const video = document.querySelector('video');
        if (video) {
          const mediaSource = new MediaSource();
          video.src = URL.createObjectURL(mediaSource);
          
          mediaSource.addEventListener('sourceopen', () => {
            const sourceBuffer = mediaSource.addSourceBuffer('video/mp4; codecs="avc1.42E01E, mp4a.40.2"');
            
            video.addEventListener('loadeddata', () => {
              const videoData = video.captureStream();
              FlutterChannel.postMessage(JSON.stringify({
                type: 'videoData',
                data: videoData
              }));
            });
          });
        }
      })();
    ''');
  }

  static Future<void> interceptNetworkRequests(
    WebViewController controller,
  ) async {
    await controller.runJavaScript('''
      (function() {
        const originalFetch = window.fetch;
        window.fetch = async function(url, options) {
          const response = await originalFetch(url, options);
          
          if (url.includes('.mp4') || response.headers.get('content-type')?.includes('video')) {
            FlutterChannel.postMessage(JSON.stringify({
              type: 'videoUrl',
              url: url
            }));
          }
          
          return response;
        };
      })();
    ''');
  }

  static Future<void> accessBrowserCache(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        const video = document.querySelector('video');
        if (video) {
          const cache = window.caches;
          cache.match(video.src).then(response => {
            if (response) {
              response.blob().then(blob => {
                FlutterChannel.postMessage(JSON.stringify({
                  type: 'cachedVideo',
                  data: blob
                }));
              });
            }
          });
        }
      })();
    ''');
  }
}
