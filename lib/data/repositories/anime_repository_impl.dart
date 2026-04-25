import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';
import '../../domain/sources/anime_source.dart';
import '../services/anime_service.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  final AnimeService _animeService;

  AnimeRepositoryImpl(this._animeService);

  @override
  AnimeSource get currentSource => _animeService.currentSource;

  @override
  void setSource(AnimeSource source) => _animeService.setSource(source);

  @override
  List<String> get availableSources => _animeService.availableSources;

  @override
  Future<List<Anime>> getAnimeList() async {
    return await _animeService.fetchAnimeList();
  }

  @override
  Future<String> getVideoUrl(String animeUrl) async {
    return await _animeService.extractVideoUrl(animeUrl);
  }

  @override
  Future<void> downloadVideo(String videoUrl, String fileName) async {
    await _animeService.downloadVideo(videoUrl, fileName);
  }
}