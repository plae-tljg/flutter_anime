# Adding New Anime Sources

## Overview

Anime-Webview supports multiple anime sources through two approaches:

| Approach | When to Use | Maintenance |
|----------|-------------|-------------|
| **Config-based** | Simple extraction patterns | Just edit JSON file |
| **Dart-based** | Complex click/wait/inject sequences | Modify Dart code |

## Quick Start: Config-Based (Recommended for Simple Sites)

### Step 1: Copy the Template

```bash
cp lib/domain/sources/configs/_template.json lib/domain/sources/configs/mysite.json
```

### Step 2: Edit the Config

```json
{
  "name": "mysite.com",
  "baseUrl": "https://www.mysite.com",
  "animeListExtractor": {
    "type": "css",
    "selector": "ul li a",
    "attr": "href",
    "textField": "text"
  },
  "videoExtractor": {
    "strategy": "direct",
    "videoSelector": "video",
    "isolateVideo": false
  }
}
```

### Step 3: Register in Source Selector

In `lib/presentation/providers/anime_provider.dart`, add:

```dart
SourceOption(id: 'config:mysite.json', name: 'mysite.com', type: SourceType.config),
```

---

## Config File Schema

### animeListExtractor

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"css"` for now |
| `selector` | string | CSS selector for anime list items |
| `attr` | string | Attribute to extract (usually `"href"`) |
| `textField` | string | `"text"` or `"innerText"` |
| `filterPatterns` | string[] | Optional - filter URLs containing these patterns |

### videoExtractor

| Field | Type | Description |
|-------|------|-------------|
| `strategy` | string | `"direct"` or `"clickWaitExtract"` |
| `videoSelector` | string | CSS selector for `<video>` element |
| `posterSelector` | string? | Selector for play button (if click-required) |
| `waitMs` | number | Milliseconds to wait after click |
| `isolateVideo` | boolean | Whether to hide non-video elements |
| `containerSelector` | string? | Container element to isolate |

---

## Strategy Types

### `direct` - Direct Video Element

For sites where `<video src="...">` is immediately available:

```json
{
  "strategy": "direct",
  "videoSelector": "video.my-selector"
}
```

### `clickWaitExtract` - Click Then Extract

For sites requiring a click on poster/play button:

```json
{
  "strategy": "clickWaitExtract",
  "posterSelector": ".vjs-poster",
  "waitMs": 1000,
  "videoSelector": ".vjscontainer",
  "isolateVideo": true,
  "containerSelector": ".vjscontainer"
}
```

**How it works:**
1. Click the element at `posterSelector`
2. Wait `waitMs` milliseconds
3. Extract `videoSelector` URL

---

## Advanced: Dart-Based Source

Use when config isn't enough - complex multi-step extraction, custom JS injection, etc.

### Example: anime1.me (Click + CSS Selector Extraction)

```dart
class Anime1MeSource implements AnimeSource {
  @override
  Future<String> extractVideoUrl(WebViewController controller, String pageUrl) async {
    await Future.delayed(Duration(seconds: 3));

    // Get dynamic CSS selector first
    final cssSelector = await _extractCssSelector(controller);

    // Then extract with that selector
    final result = await controller.runJavaScriptReturningResult('''
      document.querySelector('${cssSelector}_html5_api')?.src
    ''');
    return result.toString().replaceAll('"', '');
  }
}
```

### When to Use Dart-Based

- Need dynamic CSS selector generation
- Multiple JS injection steps
- Custom cookie/auth handling
- Non-standard video player structures

---

## Analyzing a New Site

### 1. Inspect Anime List Page

```javascript
// In browser console
document.querySelectorAll('ul li a').forEach(el => {
  console.log(el.href, el.textContent);
});
```

### 2. Inspect Video Page

```javascript
// Check if video element exists
document.querySelector('video')?.src

// Check for video.js
document.querySelector('.vjs-container')

// Check for click-required poster
document.querySelector('.vjs-poster')
```

### 3. Test Extraction

```javascript
// Direct
document.querySelector('video')?.src

// Click-required
document.querySelector('.vjs-poster')?.click()
setTimeout(() => document.querySelector('#video_html5_api')?.src, 1000)
```

---

## Registering a New Source

### Config-Based

1. Create `lib/domain/sources/configs/mysite.json`
2. Add to `availableSourcesProvider` in `anime_provider.dart`:

```dart
SourceOption(id: 'config:mysite.json', name: 'mysite.com', type: SourceType.config),
```

### Dart-Based

1. Create `lib/domain/sources/mysite_source.dart`
2. Implement `AnimeSource` interface
3. Add to `availableSourcesProvider`:

```dart
SourceOption(id: 'mysite', name: 'mysite.com', type: SourceType.dart),
```

4. Add switch case in `anime_service.dart`:

```dart
case 'mysite':
  _currentSource = MysiteSource();
  break;
```

---

## Testing Checklist

- [ ] Anime list loads and displays
- [ ] Clicking anime navigates to video page
- [ ] Video element found and URL extracted
- [ ] Video plays in WebView
- [ ] Video-only mode works (if applicable)
- [ ] Downloads work (if applicable)

---

## Troubleshooting

### "Could not find video element"

1. Site may require click first
2. CSS selector doesn't match HTML
3. Video loads dynamically - add `waitMs`
4. Check WebView JavaScript console

### Anime list empty

1. CSS selector wrong for list items
2. Site uses JS rendering (can't fetch HTML)
3. Auth required - may need cookies

### Config changes not taking effect

1. Clear app cache
2. Restart app
3. Check JSON syntax is valid