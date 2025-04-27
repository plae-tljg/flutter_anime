import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

mixin jsMethods {
    void injectJavaScript(String css_selector, webview_flutter.WebViewController _controller) {
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

    void includeOnlyElement( webview_flutter.WebViewController _controller ) {
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

  Future<String> extractCssSelector( webview_flutter.WebViewController _controller ) async {
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

    void redirectToURL(String url, webview_flutter.WebViewController _controller ) {
    _controller.loadUrl(url);
  }

}