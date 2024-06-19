import '../models/anime.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimeService {
  static Future<List<Anime>> fetchAnimeData() async {
    final url = Uri.parse('https://anime1.me/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final document = parseHtmlString(response.body);

      final animeList = document.querySelectorAll('ul')[1].querySelectorAll('li');
      final animes = animeList.map((element) {
        final animeName = element.querySelector('a')?.text.trim();
        final animeUrl = element.querySelector('a')?.attributes['href'];
        return Anime(name: animeName ?? '', url: animeUrl ?? '');
      }).toList();

      return animes;
    } else {
      throw Exception('Failed to load anime data');
    }
  }

  // Helper function to parse HTML string (you might need to adjust this)
  static dynamic parseHtmlString(String htmlString) {
    // You can use a library like html or another HTML parsing library here
    // Example using html package:
    // import 'package:html/parser.dart';
    // return parse(htmlString);
  }
}