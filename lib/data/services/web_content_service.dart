import 'package:webview_flutter/webview_flutter.dart';
import '../../core/debug/webview_debug_service.dart';

class WebContentService {
  static const String _videoSelector = 'video.vjs-tech';
  static const String _videoContainerSelector = '.vjscontainer';

  static Future<String> extractVideoUrl(WebViewController controller) async {
    try {
      // 设置调试通道
      WebViewDebugService.setupDebugChannels(controller);
      await WebViewDebugService.injectDebugScripts(controller);

      // 检查视频元素
      await WebViewDebugService.inspectVideoElement(controller);

      // 等待视频元素加载
      await Future.delayed(const Duration(seconds: 2));

      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          console.log('开始提取视频URL...');
          
          const videoElement = document.querySelector('$_videoSelector');
          if (videoElement) {
            const src = videoElement.src || videoElement.currentSrc || '';
            console.log('视频URL:', src);
            return src.startsWith('//') ? 'https:' + src : src;
          }
          
          const container = document.querySelector('$_videoContainerSelector');
          if (container) {
            const video = container.querySelector('video');
            if (video) {
              const src = video.src || video.currentSrc || '';
              console.log('容器中视频URL:', src);
              return src.startsWith('//') ? 'https:' + src : src;
            }
          }
          
          console.error('未找到视频元素');
          return '';
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

  static Future<void> isolateVideoElement(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        console.log('开始隔离视频元素...');
        
        // 等待视频元素加载
        const waitForElement = (selector, timeout = 5000) => {
          return new Promise((resolve, reject) => {
            const startTime = Date.now();
            const checkElement = () => {
              const element = document.querySelector(selector);
              if (element) {
                console.log('找到元素:', selector);
                resolve(element);
              } else if (Date.now() - startTime >= timeout) {
                console.error('未找到元素:', selector);
                reject(new Error('Element not found'));
              } else {
                setTimeout(checkElement, 100);
              }
            };
            checkElement();
          });
        };

        // 主函数
        (async () => {
          try {
            console.log('等待视频容器加载...');
            const container = await waitForElement('$_videoContainerSelector');
            console.log('视频容器:', container);
            
            console.log('等待视频元素加载...');
            const videoElement = await waitForElement('$_videoSelector');
            console.log('视频元素:', videoElement);

            // 保存视频元素和其父容器
            const videoHtml = container.outerHTML;
            console.log('视频HTML:', videoHtml);
            
            // 清空页面
            document.body.innerHTML = '';
            
            // 添加视频容器
            document.body.innerHTML = videoHtml;
            
            // 设置样式
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.body.style.backgroundColor = '#000';
            
            // 重新获取视频元素并设置属性
            const newVideo = document.querySelector('$_videoSelector');
            console.log('新视频元素:', newVideo);
            
            if (newVideo) {
              newVideo.style.width = '100%';
              newVideo.style.height = '100%';
              newVideo.controls = true;
              newVideo.autoplay = true;
              newVideo.playsInline = true;
              
              // 确保视频可以播放
              newVideo.addEventListener('canplay', () => {
                console.log('视频可以播放');
                newVideo.play().catch(e => console.error('播放失败:', e));
              });
            }
          } catch (e) {
            console.error('错误:', e);
          }
        })();
      })();
    ''');
  }
}
