import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inappwebview;
import 'dart:io';

class AnimeWebViewScreen extends StatefulWidget {

  final String animeUrl;
  const AnimeWebViewScreen({super.key, required this.animeUrl});

  @override
  _AnimeWebViewScreen createState() => _AnimeWebViewScreen();
}

class _AnimeWebViewScreen extends State<AnimeWebViewScreen> {
  late webview_flutter.WebViewController _controller;
  String urlFromJs = '';

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition for Android.
    if (Platform.isAndroid) {
      webview_flutter.WebView.platform = webview_flutter.SurfaceAndroidWebView();
    }
  }

  void _injectJavaScript() {
    _controller.runJavascript('''
      var srcElement = document.querySelector('#vjs-dtcz3_html5_api');
      if (srcElement) {
        var srcUrl = srcElement.src;
        FlutterChannel.postMessage(srcUrl);
      }
    ''');
  }

  void _includeOnlyElement() {
    _controller.runJavascript(
      """
// document.body.style.display = 'none';

 // Select the element you want to retain
const targetElement = document.querySelector('.vjscontainer');

if (targetElement) {
    // Remove all siblings and other elements-
    const allElements = document.body.children;
    for (let i = allElements.length - 1; i >= 0; i--) {
        const element = allElements[i];
        if (element !== targetElement) {
            element.remove();
        }
    }
    
    // Move the target element to the body directly
    document.body.appendChild(targetElement);
} else {
    console.log("Element with class '.vjs-poster' not found.");
}

document.body.style.display = 'block';
// document.body.style.height = '300%'
      """
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
  try {
    // Check and request permission
    if (await Permission.storage.request().isGranted) {
      // Get the directory for saving the file
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory?.path}/$fileName';
      final file = File(filePath);
      print('point a');
      // Download the file
      final response = await http.get(Uri.parse(url));
      await file.writeAsBytes(response.bodyBytes);

      print('Downloaded file saved to $filePath');
    } else {
      print('Storage permission denied');
    }
  } catch (e) {
    print('Error downloading file: $e');
  }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Anime WebView')),
      body: Stack(
        children: [
            webview_flutter.WebView(
              initialUrl: widget.animeUrl,
              javascriptMode: webview_flutter.JavascriptMode.unrestricted,
              onWebViewCreated: (webview_flutter.WebViewController webViewController) {
                _controller = webViewController;
              },
              navigationDelegate: (webview_flutter.NavigationRequest request) async {
                if (request.url.startsWith(widget.animeUrl)) {
                  // Inject JavaScript to hide the body immediately
                  await _controller.runJavascript(
                    "document.addEventListener('DOMContentLoaded', function() { document.body.style.display = 'none'; });"
                  );
                }
                return webview_flutter.NavigationDecision.navigate;
              },
              onPageStarted: (String url) {
                _controller.runJavascript('''
                  document.documentElement.style.display = 'none';
                ''');
              },
              onPageFinished: (String url) {
                _includeOnlyElement();
                _injectJavaScript();
                _redirectToURL(urlFromJs);
              },
              javascriptChannels: <webview_flutter.JavascriptChannel>{
                webview_flutter.JavascriptChannel(
                  name: 'FlutterChannel',
                  onMessageReceived: (webview_flutter.JavascriptMessage message) {
                    print(message.message);
                    setState(() {
                      urlFromJs = message.message;
                    });
                  },
                ),
              },
            ),
            Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
              DateTime now = DateTime.now();
              print('1');
              print(urlFromJs);
              _downloadFile(urlFromJs, '$now.mp4');
              },
              child: Icon(Icons.download),
            ),
          )
        ]
      )
    );
  }

  void _redirectToURL(String url) {
    _controller.loadUrl(url);
  }
}

