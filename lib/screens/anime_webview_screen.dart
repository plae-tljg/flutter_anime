import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AnimeWebViewScreen extends StatelessWidget {
  final String animeUrl;

  const AnimeWebViewScreen({super.key, required this.animeUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anime WebView')),
      body: WebView(
        initialUrl: animeUrl,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}