import 'package:webview_flutter/webview_flutter.dart';
import '../entities/anime.dart';

abstract class AnimeSource {
  String get name;
  String get baseUrl;

  Future<List<Anime>> getAnimeList();
  Future<String> extractVideoUrl(WebViewController controller, String pageUrl);
  String get videoSelector;
  bool get requiresClick;
}

class VideoExtractionResult {
  final String url;
  final String method;

  VideoExtractionResult({required this.url, required this.method});
}

class AnimeSourceConfig {
  final String name;
  final String baseUrl;
  final String videoSelector;
  final bool requiresClick;
  final bool requiresUserAgent;
  final Map<String, String> headers;

  const AnimeSourceConfig({
    required this.name,
    required this.baseUrl,
    required this.videoSelector,
    this.requiresClick = false,
    this.requiresUserAgent = false,
    this.headers = const {},
  });
}