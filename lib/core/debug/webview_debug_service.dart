import 'package:webview_flutter/webview_flutter.dart';

class WebViewDebugService {
  static void setupDebugChannels(WebViewController controller) {
    // 添加控制台日志通道
    controller.addJavaScriptChannel(
      'consoleLog',
      onMessageReceived: (JavaScriptMessage message) {
        print('WebView控制台: ${message.message}');
      },
    );

    // 添加错误日志通道
    controller.addJavaScriptChannel(
      'consoleError',
      onMessageReceived: (JavaScriptMessage message) {
        print('WebView错误: ${message.message}');
      },
    );

    // 添加DOM检查通道
    controller.addJavaScriptChannel(
      'domInspector',
      onMessageReceived: (JavaScriptMessage message) {
        print('DOM检查: ${message.message}');
      },
    );
  }

  static Future<void> injectDebugScripts(WebViewController controller) async {
    await controller.runJavaScript('''
      // 重写控制台方法
      const originalConsole = {
        log: console.log,
        error: console.error,
        warn: console.warn,
        info: console.info
      };

      // 重写console.log
      console.log = function() {
        const args = Array.from(arguments);
        const message = args.map(arg => 
          typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
        ).join(' ');
        window.consoleLog.postMessage(message);
        originalConsole.log.apply(console, args);
      };

      // 重写console.error
      console.error = function() {
        const args = Array.from(arguments);
        const message = args.map(arg => 
          typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
        ).join(' ');
        window.consoleError.postMessage(message);
        originalConsole.error.apply(console, args);
      };

      // 添加DOM检查函数
      window.inspectElement = function(selector) {
        const element = document.querySelector(selector);
        if (element) {
          const elementInfo = {
            tagName: element.tagName,
            id: element.id,
            className: element.className,
            attributes: Array.from(element.attributes).map(attr => ({
              name: attr.name,
              value: attr.value
            })),
            innerHTML: element.innerHTML,
            outerHTML: element.outerHTML
          };
          window.domInspector.postMessage(JSON.stringify(elementInfo));
        } else {
          window.consoleError.postMessage('Element not found: ' + selector);
        }
      };
    ''');
  }

  static Future<void> inspectVideoElement(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        console.log('开始检查视频元素...');
        
        // 检查视频容器
        const container = document.querySelector('.vjscontainer');
        if (container) {
          console.log('找到视频容器');
          window.inspectElement('.vjscontainer');
        } else {
          console.error('未找到视频容器');
        }
        
        // 检查视频元素
        const video = document.querySelector('video.vjs-tech');
        if (video) {
          console.log('找到视频元素');
          window.inspectElement('video.vjs-tech');
          
          // 检查视频源
          console.log('视频源:', video.src || video.currentSrc);
          console.log('视频属性:', {
            controls: video.controls,
            autoplay: video.autoplay,
            paused: video.paused,
            currentTime: video.currentTime,
            duration: video.duration,
            readyState: video.readyState
          });
        } else {
          console.error('未找到视频元素');
        }
      })();
    ''');
  }
}
