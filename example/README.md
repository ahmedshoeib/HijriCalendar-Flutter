# Hijri Calendar showcase

This app exercises the local package through a path dependency. Android, iOS, web, Windows, macOS, and Linux runner projects are included.

```sh
flutter pub get
flutter run -d chrome
```

Use `flutter devices` to find another target. Desktop runners require their corresponding host OS; iOS requires macOS/Xcode. Choose your own development team in Xcode when running on a physical Apple device. Simulator builds do not need signing.

The showcase covers all four calculation systems, selection modes, Arabic/English, RTL overrides, time zones, first weekday, local adjustments, official month starts, bounds, event dots, disabled Fridays, custom labels, and light/dark themes. The layout places settings beside the calendar on wide screens and below it on phones.

Official starts must come from the authority selected by the host application. Enter a Gregorian civil day in the form to apply it to the displayed Hijri month. Invalid month intervals are shown as form errors.

```sh
flutter test
flutter build web --release
flutter build web --wasm --release
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
flutter build macos --debug
# On the corresponding host:
flutter build windows --debug
flutter build linux --debug
```

The package's pub.dev installation instructions and full API examples are in the root README.
