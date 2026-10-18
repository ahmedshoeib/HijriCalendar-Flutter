# Contributing

Use Flutter 3.38.1+ / Dart 3.10+; CI also exercises current stable Flutter. Use your own repository-scoped credential when pushing contributions. Do not commit tokens, SSH keys, personal signing teams, local SDK paths, or generated build artifacts.

Before a pull request:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test --coverage
flutter test --platform chrome
cd example
flutter test
flutter build web --release
```

Run native builds on the corresponding host OS. Platform CI builds cover web (JS and WASM), Android, iOS simulator, macOS, Windows, and Linux. Supported platforms are a test obligation, not just pubspec metadata.

Keep engine code portable and independent from Flutter widgets, networking, global language state, and platform calendar APIs. Preserve the correction precedence and selection behavior documented in the README. Add independent conversion cases when changing calendar data; see `documentation/architecture.md` for regeneration.
