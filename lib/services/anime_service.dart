import '../models/anime.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:logger/logger.dart';
import 'dart:io'; // Import for SocketException
import '../models/error.dart';

class AnimeService {
  static Future<List<Anime>> fetchAnimeData() async {
    final url = Uri.parse('https://anime1.me/');
    Logger logger = Logger();

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        logger.d(response.body);

        final document = parse(response.body);
        final animeList = document.querySelectorAll('ul li a');

        List<Anime> animes = animeList.map((element) {
          final animeName = element.text.trim();
          final animeUrl = element.attributes['href'] ?? '';
          return Anime(name: animeName, url: animeUrl);
        }).toList();

        return animes;
      } else {
        throw Exception('Failed to load anime data: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // Handle network errors here
      ErrorLogger.instance.logCustomError('No internet connection: $e');
      throw Exception('No internet connection');
    } catch (error) {
      // Handle other types of errors here
      ErrorLogger.instance.logCustomError('Failed to fetch anime data: $error');
      throw Exception('Failed to load anime data');
    }
  }
}