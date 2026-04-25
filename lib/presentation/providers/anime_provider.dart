import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';
import '../../domain/sources/anime_source.dart';
import '../../domain/sources/anime1_me_source.dart';
import '../../domain/sources/agedm_source.dart';
import '../../domain/sources/generic_config_source.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/log_service.dart';

final animeServiceProvider = Provider<AnimeRepository>((ref) {
  return getIt<AnimeRepository>();
});

final logServiceProvider = Provider<LogService>((ref) {
  return getIt<LogService>();
});

final currentSourceProvider = StateProvider<AnimeSource>((ref) {
  return Anime1MeSource();
});

final animeListProvider = FutureProvider<List<Anime>>((ref) async {
  final repository = ref.watch(animeServiceProvider);
  final source = ref.watch(currentSourceProvider);
  repository.setSource(source);
  return await repository.getAnimeList();
});

final selectedAnimeProvider = StateProvider<Anime?>((ref) => null);

final videoUrlProvider = FutureProvider.family<String, String>((ref, animeUrl) async {
  final repository = ref.watch(animeServiceProvider);
  return await repository.getVideoUrl(animeUrl);
});

final downloadProgressProvider = StateProvider.family<double?, String>((ref, videoUrl) => null);

class AnimeNotifier extends StateNotifier<AsyncValue<List<Anime>>> {
  final AnimeRepository _repository;
  final LogService _logger;

  AnimeNotifier(this._repository, this._logger) : super(const AsyncValue.loading());

  Future<void> loadAnimeList() async {
    state = const AsyncValue.loading();
    try {
      final animes = await _repository.getAnimeList();
      state = AsyncValue.data(animes);
    } catch (e, st) {
      _logger.error('Failed to load anime list', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> getVideoUrl(String animeUrl) async {
    _logger.info('Getting video URL for: $animeUrl');
    return await _repository.getVideoUrl(animeUrl);
  }

  Future<void> downloadVideo(String videoUrl, String fileName) async {
    await _repository.downloadVideo(videoUrl, fileName);
  }

  void switchSource(AnimeSource source) {
    _repository.setSource(source);
    loadAnimeList();
  }

  void switchSourceByName(String name) {
    AnimeSource source;
    switch (name) {
      case 'anime1.me':
        source = Anime1MeSource();
        break;
      case 'agedm.com':
        source = AgedmSource();
        break;
      case 'config:anime1_me.json':
        source = GenericConfigSource('lib/domain/sources/configs/anime1_me.json');
        break;
      case 'config:agedm.json':
        source = GenericConfigSource('lib/domain/sources/configs/agedm.json');
        break;
      default:
        _logger.error('Unknown source: $name');
        return;
    }
    switchSource(source);
  }
}

final animeNotifierProvider = StateNotifierProvider<AnimeNotifier, AsyncValue<List<Anime>>>((ref) {
  final repository = ref.watch(animeServiceProvider);
  final logger = ref.watch(logServiceProvider);
  return AnimeNotifier(repository, logger);
});

final availableSourcesProvider = Provider<List<SourceOption>>((ref) {
  return [
    SourceOption(id: 'anime1.me', name: 'anime1.me', type: SourceType.dart),
    SourceOption(id: 'agedm.com', name: 'agedm.com', type: SourceType.dart),
    SourceOption(id: 'config:anime1_me.json', name: 'anime1.me (config)', type: SourceType.config),
    SourceOption(id: 'config:agedm.json', name: 'agedm.com (config)', type: SourceType.config),
  ];
});

enum SourceType { dart, config }

class SourceOption {
  final String id;
  final String name;
  final SourceType type;

  SourceOption({required this.id, required this.name, required this.type});
}