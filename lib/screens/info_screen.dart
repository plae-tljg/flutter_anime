import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../services/anime_service.dart';
import '../utils/navigation_helper.dart';

class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  List<Anime> animes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimeData();
  }

  Future<void> _fetchAnimeData() async {
    try {
      final fetchedAnimes = await AnimeService.fetchAnimeData(); // Assuming you have an AnimeService
      setState(() {
        animes = fetchedAnimes;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching anime data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // ... (your existing code for fetching and parsing anime data)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anime List')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: animes.length,
              itemBuilder: (context, index) {
                final anime = animes[index];
                return ListTile(
                  title: Text(anime.name),
                  onTap: () {
                    launchAnimePage(context, anime.url);
                  },
                );
              },
            ),
    );
  }

}