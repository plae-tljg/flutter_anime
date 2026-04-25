import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/entities/anime.dart';
import '../../data/models/anime_model.dart';
import 'anime_source.dart';
import '../../core/services/log_service.dart';

class AgedmSource implements AnimeSource {
  final LogService _logger = LogService();

  @override
  String get name => 'agedm.com';

  @override
  String get baseUrl => 'https://www.agedm.com';

  @override
  String get videoSelector => 'video.art-video';

  @override
  bool get requiresClick => false;

  @override
  Future<List<Anime>> getAnimeList() async {
    try {
      _logger.info('Fetching anime list from agedm.com');
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final animeElements = document.querySelectorAll('.video-list a, .anime-item a, a[href*="/video/"]');
        _logger.debug('Found ${animeElements.length} anime entries');

        if (animeElements.isEmpty) {
          animeElements.addAll(document.querySelectorAll('a[href]'));
        }

        return animeElements.map((element) {
          final href = element.attributes['href'] ?? '';
          return AnimeModel(
            id: href,
            title: element.text.trim().isNotEmpty ? element.text.trim() : 'Anime',
            url: href.startsWith('http') ? href : '$baseUrl$href',
          );
        }).where((anime) => anime.id.isNotEmpty && anime.url.isNotEmpty).toList();
      } else {
        throw Exception('Failed to load anime list: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.error('Error fetching anime list', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> extractVideoUrl(WebViewController controller, String pageUrl) async {
    _logger.info('Extracting video URL from agedm.com: $pageUrl');

    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        const video = document.querySelector('video.art-video');
        if (video && video.src) {
          return video.src;
        }
        const videoEl = document.querySelector('video');
        if (videoEl && videoEl.src) {
          return videoEl.src;
        }
        return '';
      })();
    ''');

    final url = result.toString().replaceAll('"', '');
    if (url.isEmpty) {
      throw Exception('Could not find video element on agedm.com');
    }

    _logger.info('Extracted video URL: $url');
    return url;
  }
}