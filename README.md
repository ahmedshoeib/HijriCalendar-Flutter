# HijriCalendar for Flutter

An inline Hijri calendar for **Android, iOS, web, Windows, macOS, and Linux**, with a portable date engine and an interactive example app. This is the Flutter companion to [HijriCalendar-iOS](https://github.com/ahmedshoeib/HijriCalendar-iOS).

## Features

- Umm al-Qura, Islamic, Civil, and Tabular calculations with consistent results on every platform
- Foundation reference data for **AH 1300–1600**, with explicit errors outside that range
- Single, multiple, range, and read-only selection
- Fixed six-week month grid and optional adjacent-month dates
- Inclusive date bounds, disabled days, event dots, and custom day builders
- Arabic and English labels, localized digits, automatic/forced RTL, and configurable first weekday
- Manual day adjustment and authority-published month-start overrides
- Theme colors, light/dark mode, large text, screen-reader semantics, and localized navigation labels
- Touch swipes, mouse interaction, keyboard navigation, and programmatic navigation
- JSON persistence, a widget-free Dart import, and no native plugins or calendar network requests

## Requirements

Flutter **3.38.1+** and Dart **3.10+**. Platform OS/architecture requirements follow the Flutter SDK used by the consuming application. The package contains shared Dart/Flutter code; it does not wrap the iOS view or call platform calendar APIs.

## Installation

```sh
flutter pub add hijri_calendar_flutter
```

Or add the dependency directly:

```yaml
dependencies:
  hijri_calendar_flutter: ^1.0.1
```

Run `flutter pub get`. The package supports Android, iOS, web, Windows, macOS, and Linux. The source repository is maintained privately; the published package includes the library, example, tests, and documentation under the MIT license.

## Basic calendar

```dart
import 'package:flutter/material.dart';
import 'package:hijri_calendar_flutter/hijri_calendar_flutter.dart';

class BookingCalendar extends StatelessWidget {
  const BookingCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return HijriCalendar(
      configuration: HijriCalendarConfiguration(
        localeIdentifier: 'ar_SA',
        timeZoneIdentifier: 'Asia/Dubai',
        firstWeekday: 7, // Sunday = 1 ... Saturday = 7, matching iOS.
      ),
      selectionMode: HijriSelectionMode.range,
      onSelectionChanged: (selection) {
        debugPrint('${selection.toJson()}');
      },
    );
  }
}
```

Place the calendar in a bounded-width layout. It sizes its own height and grows with text scaling; wrap the containing screen in a scroll view if needed. A width of at least 280 logical pixels is recommended. There is no required fixed height.

## Controller and selection

A controller exposes the same calendar state to your app and the widget. Dispose it with the owning screen.

```dart
final controller = HijriCalendarController(
  configuration: HijriCalendarConfiguration(),
  selectionMode: HijriSelectionMode.multiple,
  displayedMonth: HijriMonth(1448, 9),
);

// In build:
HijriCalendar(
  controller: controller,
  onSelectionChanged: (selection) { /* update your app */ },
  onDisplayedMonthChanged: (month) { /* load event data */ },
);

// Elsewhere:
controller.select(HijriDate(1448, 9, 10));
controller.nextMonth();
controller.previousMonth();
controller.display(HijriMonth(1448, 10));
controller.displayToday();
controller.clearSelection();
controller.refresh(); // Re-evaluate event decorations and today's marker.
```

Configure an external controller directly instead of passing widget configuration/initial values. Without a controller, the widget owns state and uses `initialSelection` and `initialDisplayedMonth` only on creation. The widget inherits the app locale when neither a configuration nor an external controller is supplied.

| Mode | Behavior |
| --- | --- |
| `none` | Date taps can notify `onDateTap`, but do not select. |
| `single` | Select one date; tapping it again clears it. |
| `multiple` | Independently toggle any number of dates. |
| `range` | First tap starts a range, second completes it (reverse order is normalized), third restarts. |

Programmatic selection obeys calendar bounds and valid lunar dates. A range includes its valid interior dates, even if an interior date is disabled by a UI decoration; decorations control which endpoints can be tapped. Changing calculation systems clears the current selection. Tightening bounds prunes invalid selections and clamps the displayed month.

## Appearance, events, and disabled dates

```dart
HijriCalendar(
  controller: controller,
  style: const HijriCalendarStyle(
    selectionColor: Colors.teal,
    todayColor: Colors.teal,
    eventColor: Colors.orange,
    dayCornerRadius: 10,
  ),
  dayDecoration: (date) => HijriCalendarDayDecoration(
    hasEvent: date.day == 1,
    isEnabled: date.day != 15,
    accessibilityLabel: date.day == 1 ? 'First day of the Hijri month' : null,
  ),
  dayLabelBuilder: (date) => 'D${date.day}',
  monthTitleBuilder: (month) => 'Hijri ${month.month} / ${month.year}',
  minimumDayLabelDigits: 2,
);
```

`dayBuilder` can replace a day's content while the package retains its tap handling, keyboard focus, and accessibility semantics. A decoration's `label` takes precedence over `dayLabelBuilder`. `weekdaySymbols` accepts exactly seven strings beginning with the configured first weekday. Day-decoration callbacks are invoked only for dates inside the public calculation range; custom cell details also include the corresponding Gregorian civil date.

## Bounds, locale, and direction

```dart
controller.configuration = controller.configuration.copyWith(
  minimumDate: HijriDate(1448, 9, 1),
  maximumDate: HijriDate(1448, 10, 29),
  localeIdentifier: 'ar_SA',
  timeZoneIdentifier: 'Asia/Riyadh',
  layoutDirection: HijriLayoutDirection.automatic,
  showsAdjacentMonthDates: false,
);
```

Bounds are inclusive. Use `clearBounds: true`, `clearMinimumDate`, or `clearMaximumDate` to remove bounds. Configuration is immutable and copied per instance. Arabic/English month and weekday translations are supplied; other languages use English names unless you supply custom labels. RTL direction is also recognized for Persian, Hebrew, Urdu, and other RTL language identifiers. Language, direction, and calculation system remain independent.

For Arabic app chrome in the example or a host app, install Flutter's standard localization delegates. The calendar itself uses its configured labels and direction.

## Date conversion without widgets

```dart
import 'package:hijri_calendar_flutter/hijri_calendar_core.dart';

final engine = HijriCalendarEngine(
  configuration: HijriCalendarConfiguration(
    calendarSystem: HijriCalendarSystem.ummAlQura,
    timeZoneIdentifier: 'Asia/Dubai',
  ),
);

final hijri = engine.fromDateTime(DateTime.now()); // Absolute instant -> local civil day.
final civil = engine.toGregorian(hijri);          // Date-only GregorianDate, or null.
final noon = engine.toDateTime(hijri);            // Noon in the configured time zone.
final direct = engine.fromGregorian(GregorianDate(2024, 3, 11));
// direct is 1 Ramadan 1445 under Umm al-Qura.
```

`GregorianDate` copies civil year/month/day fields and does not infer a time zone. Use `fromDateTime` when the input is an instant. `timeZoneIdentifier` supports `local` (the device's local zone), `UTC`, and IANA names. Named-zone data is embedded and requires no app initialization or HTTP call. Civil-day arithmetic avoids daylight-saving errors caused by adding a fixed 24-hour duration. A historically skipped civil day (for example, Samoa's 2011-12-30) cannot be converted to a local instant and produces a `StateError`.

`toGregorian`/`toDateTime` return null for nonexistent lunar dates such as day 30 of a 29-day month. Unsupported years or Gregorian days throw `RangeError`; invalid configuration throws `ArgumentError`. Persist the calendar system alongside Hijri components.

## Official month starts and manual adjustment

```dart
var configuration = HijriCalendarConfiguration(dayAdjustment: 1);

configuration = configuration.withMonthStartOverride(
  HijriMonth(1448, 9),
  GregorianDate(2027, 2, 9), // Illustrative only; use your authority's published day.
);
controller.configuration = configuration;
```

Precedence matches iOS: **official month-start overrides → manual adjustment → reference calculation**. Once any override is present, the authority timeline supersedes the whole-calendar adjustment in both conversion directions. An anchor propagates backward before the earliest published start and forward until the next anchor using the selected calculation's intervening month lengths. The last duplicate month entry wins. All effective month intervals must remain 29 or 30 days; invalid timelines are rejected when constructing the engine.

Adjustments are clamped to `-2...2`. Positive values show a later Hijri day. Remove an override with `withMonthStartOverride(month, null)`. The package does not fetch an authority, infer it from a country, or observe sunset; the host app supplies and persists its chosen official starts. Days follow civil midnight in the configured zone.

## Persistence

Models, configuration, and selection expose `toJson`/`fromJson`. Official starts are stored as `YYYY-MM-DD` Gregorian civil days. This Flutter JSON schema is not a direct decoder for Swift's synthesized `Codable` enum/Date formats; see [iOS parity](documentation/ios-parity.md).

## Example app

```sh
cd example
flutter pub get
flutter run -d chrome   # Or macos, windows, linux, an Android device, or an iOS simulator.
```

The responsive showcase includes runtime systems, language, direction, time zone, first weekday, adjustments, official starts, every selection mode, bounds, events, disabled dates, custom labels, and light/dark themes. All six platform runner projects are included. Native build tools are needed only for the platform you run.

## Validation and reference data

```sh
flutter pub get
flutter analyze
flutter test --coverage
flutter test --platform chrome
cd example
flutter test
flutter build web --release
```

Tests include 4,688 independent Foundation conversion observations, 4,192 corrected round trips generated using the actual iOS resolver, exhaustive daily round trips across all four supported calendars, date boundaries, time zones/DST, serialization, selection, accessibility semantics, keyboard interaction, RTL, and narrow/large-text layouts.

The checked-in month masks use Foundation on macOS 26.6.2. They pin a reference version so results remain consistent across devices and browser releases. They do not claim that every future Apple OS release or every local moon-sighting declaration will match. [Architecture and regeneration](documentation/architecture.md) explain the data source and update process. [CI](.github/workflows/ci.yml) validates package behavior and example builds across the supported platform families.

## License

MIT. See [LICENSE](LICENSE). The `intl` and `timezone` dependencies retain their respective upstream licenses. Reference calendar values are generated by the included maintainer tools; no third-party calendar algorithm source is vendored.
