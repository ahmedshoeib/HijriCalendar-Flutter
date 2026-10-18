# iOS behavior and Flutter behavior

| Area | Flutter implementation |
| --- | --- |
| Calculation systems | Same four Foundation identifier concepts; a pinned Foundation dataset replaces runtime Apple calculations. |
| Public conversion range | AH 1300–1600, explicitly checked; the native package delegates its range to the OS. |
| Month grid | Fixed 42 cells; optional adjacent dates; edge padding cannot be selected. |
| Selection | Same single toggle, multiple toggle, normalized range, third-tap restart, and read-only rules. |
| Bounds | Inclusive, enforced for user and programmatic selection and month navigation. |
| Day adjustment | Same -2...2 clamp and positive-day convention. |
| Official month starts | Same valid timeline precedence, projection, and duplicate-last-wins behavior. |
| Invalid official intervals | Flutter throws on engine construction; native inverse conversion can return nil and forward conversion can fall back. |
| Weekday numbering | Sunday = 1 through Saturday = 7, preserved from Foundation configuration. |
| Language | Built-in Arabic/English translations and digits; custom labels/builders extend them. Native Foundation can supply additional translations. |
| Direction | Automatic by locale, or explicitly forced; logical navigation is mirrored in RTL. |
| Appearance | Shared Flutter rendering, theming, and cell builders across six platforms, rather than native UIKit/SwiftUI views. |
| Accessibility | Localized semantic labels and selected/disabled states, focus, and adaptive text size. Platform screen-reader integration still depends on Flutter. |
| Persistence | Explicit Flutter JSON schema. Native synthesized Codable Date/enum payloads require migration. |
| Corrections and networking | Host-owned authority choice, fetching, verification, and persistence; calendar remains offline. |

The base reference fixture includes 4,688 samples taken directly from Foundation across the complete supported range and each calculation system. The correction fixture includes 4,192 samples produced by compiling the native iOS engine sources. Tests compare both directions. Exhaustive daily round trips additionally catch internal conversion gaps or overlaps, but are not by themselves proof against an independent calendar authority.

When migrating native data, convert every `HijriMonthStartOverride.gregorianStartDate` instant into its Gregorian year/month/day in the source configuration's time zone before creating a Flutter `GregorianDate`. Persist the calculation-system name and zone together with components. Do not copy Foundation epoch numbers into the civil-day string field.

This implementation does not promise live equivalence with every past/future Apple OS version, sunset-based religious days, or a country's moon-sighting declaration without its published overrides.
