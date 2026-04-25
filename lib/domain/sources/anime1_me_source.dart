import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/entities/anime.dart';
import '../../data/models/anime_model.dart';
import 'anime_source.dart';
import '../../core/services/log_service.dart';

class Anime1MeSource implements AnimeSource {
  final LogService _logger = LogService();

  @override
  String get name => 'anime1.me';

  @override
  String get baseUrl => 'https://anime1.me';

  @override
  String get videoSelector => '.vjscontainer';

  @override
  bool get requiresClick => true;

  @override
  Future<List<Anime>> getAnimeList() async {
    try {
      _logger.info('Fetching anime list from anime1.me');
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final animeElements = document.querySelectorAll('ul li a');
        _logger.debug('Found ${animeElements.length} anime entries');

        return animeElements.map((element) {
          return AnimeModel(
            id: element.attributes['href'] ?? '',
            title: element.text.trim(),
            url: element.attributes['href'] ?? '',
          );
        }).toList();
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
    _logger.info('Extracting video URL from: $pageUrl');

    await Future.delayed(const Duration(seconds: 3));

    final cssSelector = await _extractCssSelector(controller);
    final result = await controller.runJavaScriptReturningResult('''
      (function() {
        let srcElement = document.querySelector('${cssSelector}_html5_api');
        let srcUrl = '';
        if (srcElement) {
          srcUrl = srcElement.src;
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

  Future<String> _extractCssSelector(WebViewController controller) async {
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

        var parentElement = document.querySelector('.vjscontainer');
        var childElement = parentElement ? parentElement.children[0] : null;

        return getCssSelector(childElement);
      })();
    ''');

    return result.toString().replaceAll('"', '');
  }
}