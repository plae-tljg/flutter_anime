import 'package:webview_flutter/webview_flutter.dart';
import '../services/log_service.dart';

class WebViewDebugService {
  static final _logger = LogService();

  static void setupDebugChannels(WebViewController controller) {
    // 只保留基本的控制台日志通道
    controller.addJavaScriptChannel(
      'consoleLog',
      onMessageReceived: (JavaScriptMessage message) {
        _logger.debug('WebView: ${message.message}');
      },
    );
  }

  static Future<void> injectDebugScripts(WebViewController controller) async {
    _logger.debug('注入WebView调试脚本');

    await controller.runJavaScript('''
      // 重写console.log以发送到Flutter
      const originalConsoleLog = console.log;
      console.log = function() {
        const args = Array.from(arguments);
        const message = args.map(arg => 
          typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
        ).join(' ');
        if (window.consoleLog) {
          window.consoleLog.postMessage(message);
        }
        originalConsoleLog.apply(console, args);
      };
    ''');
  }

  static Future<void> inspectVideoElement(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        console.log('开始检查视频元素...');
        
        // 检查视频容器
        const container = document.querySelector('.vjscontainer') || 
                         document.querySelector('.video-js') || 
                         document.querySelector('video');
        
        if (container) {
          console.log('找到视频容器');
          window.inspectElement(container.tagName + (container.className ? '.' + container.className : ''));
        } else {
          console.error('未找到视频容器');
        }
        
        // 检查视频元素
        const video = document.querySelector('video');
        if (video) {
          console.log('找到视频元素');
          window.inspectElement('video');
          
          // 检查视频源
          console.log('视频源:', video.src || video.currentSrc);
          console.log('视频属性:', {
            controls: video.controls,
            autoplay: video.autoplay,
            paused: video.paused,
            currentTime: video.currentTime,
            duration: video.duration,
            readyState: video.readyState,
            networkState: video.networkState,
            error: video.error ? {
              code: video.error.code,
              message: video.error.message
            } : null
          });
        } else {
          console.error('未找到视频元素');
        }
      })();
    ''');
  }
}
