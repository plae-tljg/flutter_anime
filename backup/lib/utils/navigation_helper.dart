import 'package:flutter/material.dart';
import '../screens/anime_webview_screen.dart';

void launchAnimePage(BuildContext context, String animeUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AnimeWebViewScreen(animeUrl: animeUrl),
    ),
  );
}