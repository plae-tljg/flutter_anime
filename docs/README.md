# Anime Webview

A clean anime streaming app that wraps anime websites in a WebView, with support for multiple anime sources and offline downloads.

## Features

- **Multiple Anime Sources**: Easily switch between different anime websites
- **Video-Only Mode**: Isolate and play just the video element for a clean viewing experience
- **Offline Downloads**: Download videos for offline viewing
- **Source Abstraction**: Architecture designed for adding new anime sources

## Architecture

```
lib/
├── domain/
│   ├── entities/          # Core data models (Anime)
│   ├── repositories/     # Repository interfaces
│   └── sources/          # Anime source abstractions (key feature)
├── data/
│   ├── models/           # Data transfer objects
│   ├── repositories/     # Repository implementations
│   └── services/         # Business logic services
├── presentation/
│   ├── providers/        # Riverpod state management
│   ├── screens/          # UI screens
│   └── widgets/          # Reusable widgets
└── core/
    ├── config/           # App configuration
    ├── di/               # Dependency injection
    └── services/         # Shared services
```

## Quick Start

### Installation

```bash
flutter pub get
flutter run
```

### Adding a New Anime Source

1. Create a new class implementing `AnimeSource` in `lib/domain/sources/`
2. Define `videoSelector` (CSS selector for `<video>` element)
3. Implement `extractVideoUrl()` based on that site's video extraction logic
4. Register in `SettingsScreen`

See [SOURCE_INTEGRATION.md](SOURCE_INTEGRATION.md) for detailed instructions.

## Supported Sources

| Source | Selector | Extraction Method |
|--------|----------|-------------------|
| anime1.me | `.vjscontainer` | Click required |
| agedm.com | `video.art-video` | Direct |

## Key Concepts

### Source Abstraction

Each anime source defines:
- `videoSelector`: CSS selector to find the video element
- `requiresClick`: Whether clicking the poster is needed to load video
- `extractVideoUrl()`: Custom extraction logic for that site

### Riverpod State Management

```dart
// Watch current source
final source = ref.watch(currentSourceProvider);

// Watch anime list
final animes = ref.watch(animeNotifierProvider);
```

## Configuration

Settings are stored in SharedPreferences:
- `default_video_only_mode`: Auto-enable video-only mode
- `use_public_download_directory`: Save to Downloads folder vs app-private