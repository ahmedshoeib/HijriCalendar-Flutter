# Architecture

The public imports are `hijri_calendar_core.dart` (no Flutter widget imports) and `hijri_calendar_flutter.dart` (core plus UI). Both belong to one Flutter package so configuration, versions, documentation, and the example remain aligned. The core's implementation is portable Dart and uses `intl` and `timezone` for formatting and named time zones. No platform channels, FFI, `dart:io`, browser-specific API, or runtime calendar service is used by the library.

## Calculation data

`calendar_data.dart` contains four generated datasets, each with one Gregorian epoch-day origin and one 12-bit month-length mask per year. A bit records whether that month has 30 rather than 29 days. The compact data is expanded once per calculation system; lookup uses binary search over month starts. Dates resolve consistently under native Dart, JavaScript, and WebAssembly.

Public conversions support AH 1300–1600 inclusive. AH 1299 and 1601 exist internally only to fill grids at the public boundaries. Padding cells are disabled, and cannot become user selections. Unsupported conversions throw rather than silently switching to another calendar convention.

The snapshot is generated using Foundation's `islamicUmmAlQura`, `islamic`, `islamicCivil`, and `islamicTabular` identifiers on macOS 26.6.2. This deliberately captures the more complicated general Islamic calculation as well as the arithmetic variants. It preserves one explicit Apple reference baseline without requiring Apple runtimes on other platforms. Generating on a different Apple OS may change data; review that as a calculation update, not routine formatting.

## Corrections

An immutable configuration is compiled into an effective month-start timeline. With no authority data, base starts move by the negative of the clamped day adjustment. With authority data, each anchor shifts the base timeline until the next exact anchor replaces it; the first anchor also projects backward. The resolver validates all adjacent effective starts as 29- or 30-day months before exposing either conversion direction. Duplicate month entries use the final supplied value.

This matches valid iOS correction timelines. Invalid timelines are rejected eagerly, avoiding the iOS resolver's asymmetric fallback/nullable behavior. A controller validates a new configuration before changing its current state.

## Civil dates and instants

`GregorianDate` represents a calendar day, with UTC-backed epoch-day arithmetic. `DateTime` represents an instant and is projected to the configured IANA or local time zone only at the boundary. `toDateTime` uses local noon and checks that the requested day exists. A fixed duration is never used for local civil-day navigation.

The timezone package's embedded default database is initialized lazily if needed. An already initialized host database is retained. The calendar does not change a host-selected `tz.local`; its own named zone is resolved per engine. The special `local` setting uses Dart's local time directly.

## UI and lifecycle

`HijriCalendarController` owns engine/configuration, displayed month, mode, and immutable selection. `HijriCalendar` either listens to an external controller or owns and disposes its internal one. Forty-two reusable focus nodes keep keyboard navigation bounded in memory. The widget preserves semantics and interaction when a cell builder replaces visual content.

Keyboard: Tab/Shift+Tab move through focusable controls; arrow keys move by day/week; Home/End move to week boundaries; PageUp/PageDown preserve the day where possible in adjacent months; Enter/Space activate a focused date. Horizontal arrows and touch swipe direction respect RTL. Disabled dates are skipped during keyboard navigation.

Custom decorations are synchronous, side-effect-free callbacks. The host app owns event loading and calls `refresh` when data changes. Runtime system changes clear selection to avoid reinterpreting stored components under a new calculation system. Calendar locale/direction are explicit per instance; no global locale mutation is performed.

## Regeneration

From this repository root, on macOS with Swift:

```sh
swift -module-cache-path /tmp/hijri-swift-cache tool/export_foundation_reference.swift
python3 tool/export_ios_corrections.py /absolute/path/to/HijriCalendar-iOS
dart format lib/src/core/calendar_data.dart test/fixtures
flutter test
```

The first exporter generates the runtime month masks and independent Gregorian-to-Hijri observations. The second compiles the actual iOS core sources and records corrected forward/reverse conversion cases for every system. It aborts if the native reference itself fails a round trip. Swift and Python are maintainer tools only.

Review source OS metadata, changed month boundaries, month lengths, and range endpoints before committing regenerated data. Keep all four systems and correction fixtures aligned. Consumers should receive deliberate calculation changes through a documented package version.
