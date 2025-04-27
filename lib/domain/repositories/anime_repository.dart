import '../entities/anime.dart';

abstract class AnimeRepository {
  Future<List<Anime>> getAnimeList();
  Future<String> getVideoUrl(String animeUrl);
  Future<void> downloadVideo(String videoUrl, String fileName);
}
