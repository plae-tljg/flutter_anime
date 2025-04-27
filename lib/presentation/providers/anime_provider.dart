import 'package:flutter/foundation.dart';
import '../../domain/entities/anime.dart';
import '../../domain/repositories/anime_repository.dart';

class AnimeProvider extends ChangeNotifier {
  final AnimeRepository _repository;
  List<Anime> _animes = [];
  bool _isLoading = false;
  String? _error;

  AnimeProvider(this._repository);

  List<Anime> get animes => _animes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAnimeList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _animes = await _repository.getAnimeList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getVideoUrl(String animeUrl) async {
    try {
      return await _repository.getVideoUrl(animeUrl);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> downloadVideo(String videoUrl, String fileName) async {
    try {
      await _repository.downloadVideo(videoUrl, fileName);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
