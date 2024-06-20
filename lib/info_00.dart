import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:webview_flutter/webview_flutter.dart';
import '/models/anime.dart';
import '/services/anime_service.dart'; // Import your service
// ... (your imports for anime data models and potentially AnimeService)

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
                    _launchAnimePage(context, anime.url);
                  },
                );
              },
            ),
    );
  }

  void _launchAnimePage(BuildContext context, String animeUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Anime Player')),
          body: WebView(
            initialUrl: animeUrl, 
            javascriptMode: JavascriptMode.unrestricted, 
          ),
        ),
      ),
    );
  }
}