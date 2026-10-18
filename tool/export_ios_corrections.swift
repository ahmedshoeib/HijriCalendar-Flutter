// Compile together with Sources/HijriCalendar/*.swift from HijriCalendar-iOS.
import Foundation

@main
struct ExportCorrections {
    static func main() throws {
        let utc = TimeZone(secondsFromGMT: 0)!
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = utc
        let format = DateFormatter()
        format.calendar = gregorian
        format.timeZone = utc
        format.locale = Locale(identifier: "en_US_POSIX")
        format.dateFormat = "yyyy-MM-dd"
        var scenarios: [[String: Any]] = []
        for system in HijriCalendarSystem.allCases {
            let base = HijriCalendarConfiguration(timeZone: utc, calendarSystem: system)
            let month = HijriMonth(year: 1448, month: 9)
            let next = HijriMonth(year: 1448, month: 10)
            let start = base.foundationDate(from: HijriDate(year: 1448, month: 9, day: 1))!
            let nextStart = base.foundationDate(from: HijriDate(year: 1448, month: 10, day: 1))!
            let length = gregorian.dateComponents([.day], from: start, to: nextStart).day!
            for scenario in 0...7 {
                var adjustment = 0
                var overrides: [HijriMonthStartOverride] = []
                if scenario < 5 { adjustment = scenario - 2 }
                else {
                    adjustment = scenario == 5 ? -2 : 2
                    let anchor = gregorian.date(byAdding: .day, value: 1, to: start)!
                    if scenario == 7 {
                        overrides.append(HijriMonthStartOverride(month: month, gregorianStartDate: gregorian.date(byAdding: .day, value: 5, to: start)!))
                    }
                    overrides.append(HijriMonthStartOverride(month: month, gregorianStartDate: anchor))
                    if scenario >= 6 {
                        overrides.append(HijriMonthStartOverride(month: next, gregorianStartDate: gregorian.date(byAdding: .day, value: length == 29 ? 2 : 0, to: nextStart)!))
                    }
                }
                let config = HijriCalendarConfiguration(timeZone: utc, calendarSystem: system, dayAdjustment: adjustment, monthStartOverrides: overrides)
                var samples: [[String: Any]] = []
                for offset in -40...90 {
                    let instant = gregorian.date(byAdding: .day, value: offset, to: start)!
                    let hijri = config.hijriDate(from: instant)
                    guard let inverse = config.foundationDate(from: hijri), gregorian.isDate(instant, inSameDayAs: inverse) else {
                        fatalError("Native reference failed to round-trip: \(system) \(scenario) \(offset)")
                    }
                    samples.append(["gregorian": format.string(from: instant), "hijri": [hijri.year, hijri.month, hijri.day]])
                }
                scenarios.append([
                    "system": system.rawValue, "adjustment": adjustment,
                    "overrides": overrides.map { ["year": $0.month.year, "month": $0.month.month, "start": format.string(from: $0.gregorianStartDate)] as [String: Any] },
                    "samples": samples
                ])
            }
        }
        let json = String(data: try JSONSerialization.data(withJSONObject: scenarios, options: [.sortedKeys]), encoding: .utf8)!
        let source = "// Generated using the actual HijriCalendar-iOS configuration resolver.\nconst iosCorrectionScenarios = \(json);\n"
        try source.write(toFile: "test/fixtures/ios_corrections.dart", atomically: true, encoding: .utf8)
        print("Generated \(scenarios.count) iOS correction scenarios (4,192 round trips).")
    }
}
