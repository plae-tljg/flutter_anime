import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../domain/entities/anime.dart';
import '../../domain/sources/anime_source.dart';
import '../../domain/sources/anime1_me_source.dart';
import '../../domain/sources/agedm_source.dart';
import '../../domain/sources/generic_config_source.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../core/services/log_service.dart';

class AnimeService {
  final LogService _logger = LogService();
  AnimeSource _currentSource = Anime1MeSource();

  AnimeSource get currentSource => _currentSource;

  void setSource(AnimeSource source) {
    _currentSource = source;
    _logger.info('Switched to source: ${source.name}');
  }

  List<String> get availableSources => ['anime1.me', 'agedm.com', 'config:anime1_me.json', 'config:agedm.json'];

  void setSourceByName(String name) {
    switch (name) {
      case 'anime1.me':
        _currentSource = Anime1MeSource();
        break;
      case 'agedm.com':
        _currentSource = AgedmSource();
        break;
      case 'config:anime1_me.json':
        _currentSource = GenericConfigSource('lib/domain/sources/configs/anime1_me.json');
        break;
      case 'config:agedm.json':
        _currentSource = GenericConfigSource('lib/domain/sources/configs/agedm.json');
        break;
      default:
        throw Exception('Unknown source: $name');
    }
  }

  Future<List<Anime>> fetchAnimeList() async {
    try {
      _logger.info('Fetching anime list from ${_currentSource.name}');
      return await _currentSource.getAnimeList();
    } catch (e, stackTrace) {
      _logger.error('Error fetching anime list', e, stackTrace);
      rethrow;
    }
  }

  Future<String> extractVideoUrl(String animeUrl) async {
    _logger.info('Extracting video URL from: $animeUrl');
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(animeUrl));

    await Future.delayed(const Duration(seconds: 3));

    final videoUrl = await _currentSource.extractVideoUrl(controller, animeUrl);

    _logger.info('Successfully extracted video URL');
    return videoUrl;
  }

  Future<void> downloadVideo(
    String videoUrl,
    String fileName, {
    Function(double)? onProgress,
  }) async {
    try {
      _logger.info('Starting download: $fileName');

      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.notification,
      ];

      for (var permission in permissions) {
        final status = await permission.status;
        if (status.isDenied) {
          _logger.warning('Requesting permission: ${permission.toString()}');
          final result = await permission.request();
          if (!result.isGranted) {
            _logger.error('Permission denied: ${permission.toString()}');
            throw Exception('Permission required: ${permission.toString()}');
          }
        }
      }

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not determine downloads directory');
      }

      if (!await downloadsDir.exists()) {
        _logger.debug('Creating downloads directory');
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/$fileName');

      if (await file.exists()) {
        _logger.warning('File already exists: ${file.path}');
        throw Exception('File already exists: ${file.path}');
      }

      _logger.debug('Downloading to: ${file.path}');
      await Dio().download(
        videoUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      _logger.info('Download complete: ${file.path}');
    } catch (e, stackTrace) {
      _logger.error('Download error', e, stackTrace);
      rethrow;
    }
  }
}