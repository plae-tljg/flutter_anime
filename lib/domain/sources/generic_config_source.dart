import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/entities/anime.dart';
import '../../data/models/anime_model.dart';
import 'anime_source.dart';
import 'extraction_strategies/extraction_strategy.dart';
import 'extraction_strategies/direct_strategy.dart';
import 'extraction_strategies/click_wait_extract_strategy.dart';
import '../../core/services/log_service.dart';

class SourceConfig {
  final String name;
  final String baseUrl;
  final Map<String, dynamic> animeListExtractor;
  final Map<String, dynamic> videoExtractor;

  SourceConfig({
    required this.name,
    required this.baseUrl,
    required this.animeListExtractor,
    required this.videoExtractor,
  });

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      animeListExtractor: json['animeListExtractor'] as Map<String, dynamic>,
      videoExtractor: json['videoExtractor'] as Map<String, dynamic>,
    );
  }
}

class GenericConfigSource implements AnimeSource {
  final LogService _logger = LogService();
  final String configPath;
  late SourceConfig _config;
  late ExtractionStrategy _strategy;

  GenericConfigSource(this.configPath);

  @override
  String get name => _config.name;

  @override
  String get baseUrl => _config.baseUrl;

  @override
  String get videoSelector => _config.videoExtractor['videoSelector'] as String;

  @override
  bool get requiresClick =>
      _config.videoExtractor['strategy'] == 'clickWaitExtract';

  Future<void> _loadConfig() async {
    if (_config != null) return;

    try {
      final jsonString = await rootBundle.loadString(configPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _config = SourceConfig.fromJson(json);

      final strategyType = _config.videoExtractor['strategy'] as String;
      switch (strategyType) {
        case 'direct':
          _strategy = DirectStrategy();
          break;
        case 'clickWaitExtract':
          _strategy = ClickWaitExtractStrategy();
          break;
        default:
          _strategy = DirectStrategy();
      }

      _logger.info('Loaded config for: ${_config.name}');
    } catch (e) {
      _logger.error('Failed to load config from $configPath', e, StackTrace.current);
      rethrow;
    }
  }

  @override
  Future<List<Anime>> getAnimeList() async {
    await _loadConfig();

    try {
      _logger.info('Fetching anime list from ${_config.name}');
      final response = await http.get(Uri.parse(_config.baseUrl));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final extractor = _config.animeListExtractor;

        final selector = extractor['selector'] as String;
        final attr = extractor['attr'] as String;
        final textField = extractor['textField'] as String;
        final filterPatterns = (extractor['filterPatterns'] as List?)?.cast<String>();

        final elements = document.querySelectorAll(selector);

        return elements.map((element) {
          final href = element.attributes[attr] ?? '';
          String text = element.text.trim();

          return AnimeModel(
            id: href,
            title: text.isNotEmpty ? text : 'Anime',
            url: href.startsWith('http') ? href : '${_config.baseUrl}$href',
          );
        }).where((anime) {
          if (filterPatterns == null || filterPatterns.isEmpty) {
            return anime.id.isNotEmpty;
          }
          return filterPatterns.any((pattern) => anime.id.contains(pattern));
        }).toList();
      } else {
        throw Exception('Failed to load anime list: ${response.statusCode}');
      }
    } catch (e, st) {
      _logger.error('Error fetching anime list', e, st);
      rethrow;
    }
  }

  @override
  Future<String> extractVideoUrl(WebViewController controller, String pageUrl) async {
    await _loadConfig();

    _logger.info('Extracting video URL from: $pageUrl');

    final videoSelector = _config.videoExtractor['videoSelector'] as String;
    final posterSelector = _config.videoExtractor['posterSelector'] as String?;
    final waitMs = _config.videoExtractor['waitMs'] as int? ?? 0;

    return await _strategy.extract(
      controller,
      cssSelector: videoSelector,
      posterSelector: posterSelector,
      waitMs: waitMs,
    );
  }

  Future<void> isolateVideoIfNeeded(WebViewController controller) async {
    await _loadConfig();

    final isolateVideo = _config.videoExtractor['isolateVideo'] as bool? ?? false;
    if (!isolateVideo) return;

    final containerSelector = _config.videoExtractor['containerSelector'] as String?;
    if (containerSelector == null) return;

    await _strategy.isolateVideo(controller, containerSelector: containerSelector);
  }

  static Future<List<String>> listAvailableConfigs() async {
    return ['anime1_me.json', 'agedm.json'];
  }
}