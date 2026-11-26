[简体中文](https://github.com/Akiyama-25/Runami-NCM/blob/main/README.md) | [繁體中文](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_TC.md) | [日本語](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_JA.md)

# Runami-NCM

A cross-platform app (**Android / Windows / iOS**) that decrypts NetEase Cloud Music's encrypted `.ncm` files into standard MP3 or FLAC format. Built with Flutter and a pure Dart + Isolate concurrent architecture, faithfully porting the UI and experience of [NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android).

## Features

- Batch conversion supporting up to 50 `.ncm` files per import with automatic filtering of non-`.ncm` files
- Pure Dart + Isolate concurrent decryption pipeline with zero native dynamic library dependencies and jank-free UI
- Automatic metadata writing (title, artist, album, cover art)
- Automatic lyric search and embedding with independent original/translated switches
- System folder picker for export directory with auto-save or manual per-file save
- Desktop (Windows) drag-and-drop file import; iOS Files app integration and Share Sheet import
- Material You dynamic colors (Android 12+ and supported platforms)
- Custom accent and background colors via live HSL gradient sliders
- Material 3 Expressive (M3E) style cards & responsive grid layout, optimized for phones, foldables, tablets, and desktops
- Reads device-installed system fonts (zero bundled font bloat, supports system font scanning across Android / Windows / iOS, search, live preview switching & 9 customizable font weights 100–900)
- Predictive back / gesture-following swipe-back transition between Home and Settings (dynamic rounded card morphing, parallax underlying page reveal)
- Double-tap back to exit (Android)
- Built-in runtime log viewer & exporter (configurable log level & `.log` / `.txt` / `.md` formats) and Markdown User Guide
- Multi-language support: Simplified Chinese, Traditional Chinese, English, Japanese

## Requirements

- **Android**: Android 8.0 (API 26) or higher (targetSdk 36)
- **Windows**: Windows 10 / 11 (x64)
- **iOS**: iOS 13.0 or higher

## Tech Stack

- Flutter + Dart (Isolate concurrent decryption) + Material 3 (M3E)
- Riverpod + `dynamic_color`
- Dio + PointyCastle (pure Dart `AES-128-ECB` / `RC4` decryption & direct NetEase EAPI client)
- `file_picker` / `desktop_drop` / `window_manager` / `path_provider`

## Build

### Local Build

```bash
git clone https://github.com/Akiyama-25/Runami-NCM.git
cd Runami-NCM
flutter pub get

# Android APK
flutter build apk --release

# Windows x64
flutter build windows --release

# iOS (unsigned)
flutter build ios --release --no-codesign
```

### GitHub Actions CI/CD

This project runs pure GitHub Actions hosted builds (`ubuntu-latest` / `windows-latest` / `macos-latest`) with persistent signing across all three platforms, uploading signed builds to Actions Artifacts:

- **Android** (`ubuntu-latest`): `flutter test` + release APK build + persistent signing via `zipalign` / `apksigner`
- **Windows** (`windows-latest`): Windows x64 release build + `signtool.exe` signing & ZIP packaging
- **iOS** (`macos-latest`): iOS release build + `codesign` & IPA packaging

## Lyrics

The automatic lyrics embedding feature includes built-in direct official NetEase API integration, working out of the box without requiring external cloud server deployments.

1. The app uses the built-in direct API by default—no server setup required to fetch and embed lyrics or cover art.
2. Once lyrics are enabled, you can independently control whether to embed "original lyrics" and "translated lyrics" (merged line-by-line when both are enabled).

> Note: The translated lyrics feature only supports Simplified Chinese translation results. When the app language is not Simplified Chinese, the translation switch will display a corresponding note.

## Reference Projects

The following projects were referenced during development:

- [Akiyama-25/NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) — Original Android project providing the UI design, interactions, and core architecture reference
- [chen08209/FlClash](https://github.com/chen08209/FlClash) — M3E expressive design and system font selector inspiration
- [rinchao0721/Melodia](https://github.com/rinchao0721/Melodia) — Architecture ideas and protocol reference for embedding a direct encrypted NetEase official API client
- [Ame-Player](https://github.com/Akiyama-25/Ame-Player) — Client-side NetEase encrypted API and release signing workflow reference
- [NLyric](https://github.com/wwh1004/NLyric) — Reference for lyrics matching strategy
- [openyyy.com](https://openyyy.com/) — Reference for NCM format parsing

## License

This project is open-sourced under the [GPL v3](https://github.com/Akiyama-25/Runami-NCM/blob/main/LICENSE) license.
