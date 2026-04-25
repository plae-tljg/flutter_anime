# Building & Release

## Development Build

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run
```

## Release Builds

### Android (APK)

```bash
# Debug APK (faster build)
flutter build apk --debug

# Release APK (optimized)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Install APK directly

```bash
# Install release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Install debug APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Replace existing installation
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Install with grant all permissions
adb install -g build/app/outputs/flutter-apk/app-release.apk
```

### Other ADB Commands

```bash
# List connected devices
adb devices

# View device log
adb logcat

# Push file to device
adb push local/path /sdcard/Download/

# Pull file from device
adb pull /sdcard/Download/file.mp4 local/path/

# Uninstall app
adb uninstall com.example.anime_webview

# Clear app data
adb shell pm clear com.example.anime_webview
```

## Build Variants

| Command | Purpose | Output Location |
|---------|---------|-----------------|
| `flutter build apk --debug` | Debug APK for testing | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | Release APK for distribution | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | App Bundle for Play Store | `build/app/outputs/bundle/release/` |
| `flutter build apk --split-per-abi` | Split APKs per architecture | `build/app/outputs/flutter-apk/` |

## Signing (Release)

### Generate Keystore

```bash
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias anime_webview
```

### Configure Signing

Edit `android/app/build.gradle`:

```groovy
android {
    ...
    signingConfigs {
        release {
            keyAlias 'anime_webview'
            keyPassword 'your_password'
            storeFile file('key.jks')
            storePassword 'your_password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Build Signed Release

```bash
flutter build apk --release
```

## Troubleshooting

### Kotlin Version Warning

If you see "Flutter support for your project's Kotlin version (1.8.22) will soon be dropped":

Update `android/build.gradle`:

```groovy
ext.kotlin_version = '2.1.0'
```

Or in `android/settings.gradle`:

```groovy
plugins {
    id "org.jetbrains.kotlin.android" version "2.1.0"
}
```

### Build Fails with Dependency Issues

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Large APK Size

Use `--split-per-abi` to generate architecture-specific APKs:

```bash
flutter build apk --split-per-abi --release
```

This creates smaller APKs:
- `app-arm64-v8a-release.apk` (~15MB)
- `app-armeabi-v7a-release.apk` (~15MB)
- `app-x86_64-release.apk` (~18MB)

Users only download the APK for their device architecture.

## CI/CD Example (GitHub Actions)

```yaml
# .github/workflows/build.yml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```