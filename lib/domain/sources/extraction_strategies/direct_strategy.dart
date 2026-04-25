import 'package:webview_flutter/webview_flutter.dart';
import 'extraction_strategy.dart';

class DirectStrategy implements ExtractionStrategy {
  @override
  ExtractionStrategyType get type => ExtractionStrategyType.direct;

  @override
  Future<String> extract(
    WebViewController controller, {
    required String cssSelector,
    int waitMs = 0,
    String? posterSelector,
  }) async {
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        let element = document.querySelector('$cssSelector');
        if (element) {
          return element.src || element.currentSrc || '';
        }
        element = document.querySelector('${cssSelector}_html5_api');
        if (element) {
          return element.src || element.currentSrc || '';
        }
        return '';
      })();
    ''');

    final url = result.toString().replaceAll('"', '');
    if (url.isEmpty) {
      throw Exception('Could not find video element with selector: $cssSelector');
    }
    return url;
  }

  @override
  Future<void> isolateVideo(
    WebViewController controller, {
    required String containerSelector,
  }) async {
    await controller.runJavaScript('''
      (function() {
        const target = document.querySelector('$containerSelector');
        if (!target) return;

        const elements = document.body.children;
        for (let i = elements.length - 1; i >= 0; i--) {
          if (elements[i] !== target) {
            elements[i].remove();
          }
        }

        document.body.style.margin = '0';
        document.body.style.padding = '0';
        document.body.style.backgroundColor = '#000';

        target.style.width = '100%';
        target.style.height = '100vh';

        const video = target.querySelector('video');
        if (video) {
          video.style.width = '100%';
          video.style.height = '100%';
          video.controls = true;
          video.playsInline = true;
        }
      })();
    ''');
  }
}