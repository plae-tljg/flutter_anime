import '../entities/anime.dart';
import '../sources/anime_source.dart';

abstract class AnimeRepository {
  Future<List<Anime>> getAnimeList();
  Future<String> getVideoUrl(String animeUrl);
  Future<void> downloadVideo(String videoUrl, String fileName);
  AnimeSource get currentSource;
  void setSource(AnimeSource source);
  List<String> get availableSources;
}