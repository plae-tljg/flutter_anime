# Template Project Guide

## What is Anime-Webview?

A maintainable WebView-based anime streaming app with **configurable source extraction**. The project is designed as a **template** - when anime sites change their HTML structure, developers can update a JSON config instead of rewriting Dart code.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer                           │
│              (Screens, Widgets, Providers)                     │
├─────────────────────────────────────────────────────────────────┤
│                      Domain Layer                               │
│   Entities │ Repositories │ Sources (Dart + Config)            │
├─────────────────────────────────────────────────────────────────┤
│                       Data Layer                                │
│         Services (AnimeService, WebContentService)             │
└─────────────────────────────────────────────────────────────────┘
```

### Source Extraction System

```
┌──────────────────────────────────────────────────────────────────┐
│                     AnimeSource Interface                        │
│  getAnimeList() + extractVideoUrl(WebViewController, pageUrl)    │
└──────────────────────────┬───────────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
   ┌────▼────┐                         ┌────▼────┐
   │  Dart   │                         │  Config │
   │ Source  │                         │  Source │
   └─────────┘                         └────┬────┘
                                            │
                         ┌──────────────────┴────────┐
                         │                           │
                  ┌──────▼──────┐            ┌──────▼──────┐
                  │   Direct    │            │ Click/Wait  │
                  │  Strategy   │            │  Strategy   │
                  └─────────────┘            └─────────────┘
```

---

## Quick Start

### Running the App

```bash
flutter pub get
flutter run
```

### Adding a New Source (Config-Based)

1. Copy template:
   ```bash
   cp lib/domain/sources/configs/_template.json mysite.json
   ```

2. Edit `mysite.json` with site-specific selectors

3. Register in `anime_provider.dart`:
   ```dart
   SourceOption(id: 'config:mysite.json', name: 'My Site', type: SourceType.config)
   ```

### Adding a New Source (Dart-Based)

For complex sites requiring custom logic:

1. Create `lib/domain/sources/mysite_source.dart`
2. Implement `AnimeSource` interface
3. Register in `anime_provider.dart` and `anime_service.dart`

---

## Project Structure

```
lib/
├── domain/
│   ├── sources/
│   │   ├── anime_source.dart           # Interface
│   │   ├── configs/                    # JSON configs
│   │   │   ├── _template.json
│   │   │   ├── anime1_me.json
│   │   │   └── agedm.json
│   │   ├── extraction_strategies/      # Reusable strategies
│   │   │   ├── extraction_strategy.dart
│   │   │   ├── direct_strategy.dart
│   │   │   └── click_wait_extract_strategy.dart
│   │   ├── implementations/            # Dart sources
│   │   │   ├── anime1_me_source.dart
│   │   │   └── agedm_source.dart
│   │   └── generic_config_source.dart  # Config reader
│   ├── entities/
│   │   └── anime.dart
│   └── repositories/
│       └── anime_repository.dart
├── data/
│   ├── services/
│   │   ├── anime_service.dart
│   │   ├── web_content_service.dart
│   │   └── cookie_service.dart
│   ├── repositories/
│   │   └── anime_repository_impl.dart
│   └── models/
│       └── anime_model.dart
├── presentation/
│   ├── providers/
│   │   └── anime_provider.dart
│   ├── screens/
│   │   ├── home/
│   │   ├── anime_list/
│   │   ├── video_player/
│   │   ├── video_library/
│   │   └── settings/
│   └── widgets/
└── core/
    ├── config/
    ├── di/
    └── services/
```

---

## Key Concepts

### Extraction Strategies

| Strategy | Use Case | Config Value |
|----------|----------|--------------|
| `Direct` | Video src is immediately available | `"strategy": "direct"` |
| `ClickWaitExtract` | Must click poster first | `"strategy": "clickWaitExtract"` |

### Config vs Dart Sources

| Config-Based | Dart-Based |
|--------------|------------|
| JSON file only | Write Dart class |
| Simple sites | Complex logic needed |
| No code changes | Full flexibility |
| Fast to modify | When config insufficient |

---

## Updating for Site Changes

When an anime site changes their HTML structure:

### Config-Based Source

1. Open `lib/domain/sources/configs/mysite.json`
2. Update selectors (e.g., `videoSelector`)
3. Update strategy if needed (`"direct"` → `"clickWaitExtract"`)
4. Restart app - no recompile needed for simple selector changes

### Dart-Based Source

1. Update CSS selector in source file
2. If extraction logic changed, update `extractVideoUrl()` method
3. Rebuild: `flutter build apk`

---

## Source Selector UI

The Settings screen includes a source selector showing all available sources:

```
┌─────────────────────────────────────┐
│  anime1.me            [Dart]       │
│  agedm.com             [Dart]      │
│  anime1.me (config)    [Config]     │
│  agedm.com (config)    [Config]     │
└─────────────────────────────────────┘
```

- **[Dart]** = Custom Dart implementation
- **[Config]** = JSON-based generic source

---

## Maintenance Tips

1. **Keep configs in sync** with actual site HTML
2. **Test on real device** - WebView behavior varies
3. **Check site periodically** - anime sites change structure often
4. **Use config-based first** - only use Dart when truly needed
5. **Document quirks** - add comments in config JSON if site has unusual behavior