import 'package:webview_flutter/webview_flutter.dart';

enum ExtractionStrategyType {
  direct,
  clickWaitExtract,
  injectIsolate,
}

abstract class ExtractionStrategy {
  ExtractionStrategyType get type;

  Future<String> extract(
    WebViewController controller, {
    required String cssSelector,
    int waitMs = 0,
    String? posterSelector,
  });

  Future<void> isolateVideo(
    WebViewController controller, {
    required String containerSelector,
  });
}