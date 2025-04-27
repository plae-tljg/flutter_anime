import 'package:flutter/material.dart';
import '../presentation/screens/anime_list/anime_list_screen.dart';
import '../presentation/screens/video_player/video_player_screen.dart';

class NavigationHelper {
  static void navigateToAnimeList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnimeListScreen()),
    );
  }

  static void navigateToVideoPlayer(
    BuildContext context,
    String animeUrl,
    String title,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VideoPlayerScreen(animeUrl: animeUrl, title: title),
      ),
    );
  }
}
