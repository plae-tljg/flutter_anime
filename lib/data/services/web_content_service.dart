import 'package:webview_flutter/webview_flutter.dart';

class WebContentService {
  static Future<String> extractVideoUrl(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          let srcElement = document.querySelector('.vjscontainer_html5_api');
          let srcUrl = '';
          if (srcElement) {
            srcUrl = srcElement.src;
          }
          return srcUrl;
        })();
      ''');
      return result.toString();
    } catch (e) {
      throw Exception('无法提取视频URL: $e');
    }
  }

  static Future<void> isolateVideoElement(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        const targetElement = document.querySelector('.vjscontainer');
        if (targetElement) {
          const allElements = document.body.children;
          for (let i = allElements.length - 1; i >= 0; i--) {
            const element = allElements[i];
            if (element !== targetElement) {
              element.remove();
            }
          }
          document.body.appendChild(targetElement);
        }
        document.body.style.display = 'block';
      })();
    ''');
  }
}
