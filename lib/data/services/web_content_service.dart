import 'package:webview_flutter/webview_flutter.dart';
import '../../core/debug/webview_debug_service.dart';

enum ExtractionStrategy {
  direct,
  clickRequired,
  postClickDelay,
}

class WebContentService {
  static Future<String> extractVideoUrl(
    WebViewController controller, {
    required String cssSelector,
    ExtractionStrategy strategy = ExtractionStrategy.direct,
    Duration clickDelay = const Duration(seconds: 1),
  }) async {
    switch (strategy) {
      case ExtractionStrategy.direct:
        return _extractDirect(controller, cssSelector);
      case ExtractionStrategy.clickRequired:
        return _extractWithClick(controller, cssSelector);
      case ExtractionStrategy.postClickDelay:
        await _clickVideoPoster(controller);
        await Future.delayed(clickDelay);
        return _extractDirect(controller, cssSelector);
    }
  }

  static Future<String> _extractDirect(
    WebViewController controller,
    String cssSelector,
  ) async {
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        let srcElement = document.querySelector('${cssSelector}_html5_api') ||
                         document.querySelector('${cssSelector}');
        let srcUrl = '';
        if (srcElement) {
          srcUrl = srcElement.src || srcElement.currentSrc || '';
        }
        return srcUrl;
      })();
    ''');

    final url = result.toString().replaceAll('"', '');
    if (url.isEmpty) {
      throw Exception('Could not find video element');
    }
    return url;
  }

  static Future<String> _extractWithClick(
    WebViewController controller,
    String cssSelector,
  ) async {
    await _clickVideoPoster(controller);
    await Future.delayed(const Duration(milliseconds: 500));
    return _extractDirect(controller, cssSelector);
  }

  static Future<void> _clickVideoPoster(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        const poster = document.querySelector('.vjs-poster');
        if (poster) {
          poster.click();
        }
      })();
    ''');
  }

  static Future<void> isolateVideoElement(
    WebViewController controller, {
    required String containerSelector,
  }) async {
    await controller.runJavaScript('''
      (function() {
        const targetElement = document.querySelector('$containerSelector');

        if (targetElement) {
          const allElements = document.body.children;
          for (let i = allElements.length - 1; i >= 0; i--) {
            const element = allElements[i];
            if (element !== targetElement) {
              element.remove();
            }
          }

          document.body.appendChild(targetElement);

          document.body.style.margin = '0';
          document.body.style.padding = '0';
          document.body.style.backgroundColor = '#000';
          document.body.style.display = 'block';

          targetElement.style.width = '100%';
          targetElement.style.height = '100vh';

          const video = targetElement.querySelector('video');
          if (video) {
            video.style.width = '100%';
            video.style.height = '100%';
            video.controls = true;
            video.playsInline = true;
            video.autoplay = false;
          }
        }
      })();
    ''');
  }

  static Future<String> extractVideoUrlFromPage(
    WebViewController controller,
    String sourceSelector,
  ) async {
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        const video = document.querySelector('$sourceSelector');
        if (video) {
          return video.src || video.currentSrc || '';
        }
        return '';
      })();
    ''');

    final url = result.toString().replaceAll('"', '');
    if (url.isEmpty) {
      throw Exception('Could not find video element with selector: $sourceSelector');
    }
    return url;
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

  static Future<String> getCssSelector(
    WebViewController controller,
    String containerSelector,
  ) async {
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

        var parentElement = document.querySelector('$containerSelector');
        var childElement = parentElement ? parentElement.children[0] : null;

        return getCssSelector(childElement);
      })();
    ''');

    return result.toString().replaceAll('"', '');
  }
}