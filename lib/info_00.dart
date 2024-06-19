import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../models/anime.dart';
import '../../services/anime_service.dart'; // Import your service

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  List<Anime> animes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimeData();
  }

  Future<void> _fetchAnimeData() async {
    try {
      final fetchedAnimes = await AnimeService.fetchAnimeData();
      setState(() {
        animes = fetchedAnimes;
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print('Error fetching anime data: $e');
      setState(() {
        isLoading = false; // Set loading to false even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Names List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: animes.length,
              itemBuilder: (context, index) {
                final anime = animes[index];
                return ListTile(
                  title: Text(anime.name),
                  subtitle: Text(anime.url),
                );
              },
            ),
    );
  }
}