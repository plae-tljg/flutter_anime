import '../models/anime.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse; // Import the 'parse' function
import 'package:logger/logger.dart'; // Import the 'logger' package

class AnimeService {
  static Future<List<Anime>> fetchAnimeData() async {
    final url = Uri.parse('https://anime1.me/');
    final response = await http.get(url);
    Logger logger = Logger(); // Uncomment this line if you have a logging framework
    logger.d(response.body); // Use the appropriate logging method instead of print

    if (response.statusCode == 200) {
      final document = parse(response.body);

      final animeList = document.querySelectorAll('ul li a');
      print(animeList);

      List<Anime> animes = animeList.map((element) {
        final animeName = element.text.trim();
        final animeUrl = element.attributes['href'] ?? '';
        return Anime(name: animeName, url: animeUrl);
      }).toList();

      return animes;
    } else {
      throw Exception('Failed to load anime data');
    }
  }
}