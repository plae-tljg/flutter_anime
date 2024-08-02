import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  String css_selectorr = "initial_value";
  @override
  void initState() {
    super.initState();
    // Enable hybrid composition for Android.
    if (Platform.isAndroid) {
      webview_flutter.WebView.platform = webview_flutter.SurfaceAndroidWebView();
    }
  }

  void _injectJavaScript(String css_selector) {
    print("injectjavascript, ${css_selector}");
    _controller.runJavascript('''
      let srcElement = document.querySelector(`${css_selector}_html5_api`);
      let srcUrl = '';
      if (srcElement) {
        srcUrl = srcElement.src;
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

  Future<String> _extractCssSelector() async {
      String cssSelector = await _controller.runJavascriptReturningResult(
"""
(function() {
  // Example: Extracts CSS selector of the first <h1> element and its first child
  function getCssSelector(element) {
    if (!element) return 'Element not found';
    var path = [];
    while (element.nodeType === Node.ELEMENT_NODE) {
      var selector = '';
      if (element.id) {
        selector += '#' + element.id;
        path.unshift(selector);
        break;
      } else {
        var sib = element, nth = 1;
        while (sib = sib.previousElementSibling) {
          if (sib.nodeName.toLowerCase() == selector)
            nth++;
        }
        if (nth != 1)
          selector += ":nth-of-type(" + nth + ")";
      }
      path.unshift(selector);
      element = element.parentNode;
    }
    return path.join(" > ");
  }

  var parentElement = document.querySelector('.vjscontainer');
  var childElement = parentElement ? parentElement.children[0] : null;

  return getCssSelector(childElement);
})();
"""
    );
    print('CSS Selector: ${cssSelector}');
  return cssSelector;
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
              javascriptChannels: <webview_flutter.JavascriptChannel>{
                webview_flutter.JavascriptChannel(
                  name: 'FlutterChannel',
                  onMessageReceived: (webview_flutter.JavascriptMessage message) {
                    print("debug point at flutter channel, "+message.message);
                    setState(() {
                      urlFromJs = message.message;
                    });
                  },
                ),
              },
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
              onPageFinished: (String url) async {
                _includeOnlyElement();
                String css_selector = await _extractCssSelector();
                css_selector = css_selector.replaceAll('"', '');
                print("debug point 1: "+css_selector);
                setState(() {
                  css_selectorr = css_selector;
                });
              },
            ),
            Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
              DateTime now = DateTime.now();
              print('1');
              _injectJavaScript(css_selectorr);
              print("debug point 2: "+urlFromJs);
              _redirectToURL(urlFromJs);
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

