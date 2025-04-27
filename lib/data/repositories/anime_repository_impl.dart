import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';
import '../services/anime_service.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  final AnimeService _animeService;

  AnimeRepositoryImpl(this._animeService);

  @override
  Future<List<Anime>> getAnimeList() async {
    try {
      return await _animeService.fetchAnimeList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> getVideoUrl(String animeUrl) async {
    try {
      return await _animeService.extractVideoUrl(animeUrl);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> downloadVideo(String videoUrl, String fileName) async {
    try {
      await _animeService.downloadVideo(videoUrl, fileName);
    } catch (e) {
      rethrow;
    }
  }
}
