# Architecture Documentation

## Overview

Anime-Webview uses **Clean Architecture** with three main layers:

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│    (Screens, Widgets, Providers)         │
├─────────────────────────────────────────┤
│             Domain Layer                │
│   (Entities, Repositories, Sources)      │
├─────────────────────────────────────────┤
│              Data Layer                 │
│    (Models, Services, Implementations)  │
└─────────────────────────────────────────┘
```

## Domain Layer

### Entities

**Anime** - Core entity representing an anime title:
```dart
class Anime {
  final String id;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final String? description;
}
```

### Repository Interface

**AnimeRepository** defines the contract:
```dart
abstract class AnimeRepository {
  Future<List<Anime>> getAnimeList();
  Future<String> getVideoUrl(String animeUrl);
  Future<void> downloadVideo(String videoUrl, String fileName);
  AnimeSource get currentSource;
  void setSource(AnimeSource source);
  List<String> get availableSources;
}
```

### Source Abstraction (Key Feature)

**AnimeSource** is the base interface for all anime sources:

```dart
abstract class AnimeSource {
  String get name;           // e.g., "anime1.me"
  String get baseUrl;        // e.g., "https://anime1.me"
  String get videoSelector;  // CSS selector for <video> element
  bool get requiresClick;    // true if poster click needed
  Future<List<Anime>> getAnimeList();
  Future<String> extractVideoUrl(WebViewController controller, String pageUrl);
}
```

**Why Source Abstraction?**

Different anime sites use different video players:
- **anime1.me**: Uses video.js with `.vjscontainer` selector, requires clicking poster
- **agedm.com**: Has direct `<video class="art-video" src="...">` elements

The abstraction allows adding new sources without modifying core logic.

## Data Layer

### Services

**AnimeService** - Orchestrates anime operations:
- Fetches list from current source
- Extracts video URLs via WebView JavaScript injection
- Handles video downloads with Dio

**WebContentService** - WebView manipulation:
- `extractVideoUrl()` - Extract direct .mp4 URL from page
- `isolateVideoElement()` - Remove all elements except video
- Supports configurable extraction strategies

### Repository Implementation

**AnimeRepositoryImpl** delegates to AnimeService, keeping data layer separate from domain.

## Presentation Layer

### Riverpod Providers

```dart
// Current source state
final currentSourceProvider = StateProvider<AnimeSource>(...);

// Anime list with loading/error states
final animeNotifierProvider = StateNotifierProvider<AnimeNotifier, AsyncValue<List<Anime>>>(...);

// Computed provider for available source names
final availableSourcesProvider = Provider<List<String>>(...);
```

### State Flow

```
User Action → Provider.notifier method → Repository → Service
                ↓
StateNotifier.state = AsyncValue<Data>
                ↓
UI rebuilds via ref.watch()
```

## Video Extraction Mechanism

### Problem
Anime sites embed videos in complex players with ads and overlays.

### Solution: JavaScript Injection

1. **Load page in WebView** with JavaScript enabled
2. **Inject JS** to query video element and extract `.src` attribute
3. **For sites requiring click**: Inject JS to click poster element first
4. **Isolate video**: Inject JS to remove all non-video DOM elements

### Example (anime1.me)

```javascript
// Click poster to initialize video player
document.querySelector('.vjs-poster')?.click();

// Get video URL
document.querySelector('#video_js_id_here_html5_api').src
```

### Example (agedm.com)

```javascript
// Direct video element
document.querySelector('video.art-video')?.src
```

## Dependency Injection

Using **GetIt** for service location:

```dart
final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<LogService>(() => LogService());
  getIt.registerLazySingleton<AnimeService>(() => AnimeService());
  getIt.registerLazySingleton<AnimeRepository>(
    () => AnimeRepositoryImpl(getIt<AnimeService>()),
  );
}
```

Riverpod then uses `getIt` to provide repository to providers.

## Build & Run

```bash
flutter pub get
flutter run
```

## Adding New Sources

See [SOURCE_INTEGRATION.md](SOURCE_INTEGRATION.md) for step-by-step guide.