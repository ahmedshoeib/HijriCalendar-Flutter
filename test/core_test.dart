import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hijri_calendar_flutter/hijri_calendar_core.dart';

import 'fixtures/foundation_dates.dart';
import 'fixtures/ios_corrections.dart';

void main() {
  final engines = {
    for (final system in HijriCalendarSystem.values)
      system: HijriCalendarEngine(
        configuration: HijriCalendarConfiguration(
          calendarSystem: system,
          timeZoneIdentifier: 'UTC',
        ),
      ),
  };

  test(
    '4,688 independent Foundation observations convert in both directions',
    () {
      for (final sample in foundationSamples) {
        final engine = engines[HijriCalendarSystem.values[sample[0]]]!;
        final civil = GregorianDate.fromEpochDay(sample[1]);
        final expected = HijriDate(sample[2], sample[3], sample[4]);
        expect(
          engine.fromGregorian(civil),
          expected,
          reason: '${engine.configuration.calendarSystem} $civil',
        );
        expect(engine.toGregorian(expected), civil);
      }
    },
  );

  test('4,192 correction round trips match the actual iOS resolver', () {
    for (final scenario in iosCorrectionScenarios) {
      final overrides = scenario['overrides']! as List<dynamic>;
      final engine = HijriCalendarEngine(
        configuration: HijriCalendarConfiguration(
          calendarSystem: HijriCalendarSystem.values.byName(
            scenario['system']! as String,
          ),
          dayAdjustment: scenario['adjustment']! as int,
          timeZoneIdentifier: 'UTC',
          monthStartOverrides: overrides.map(
            (dynamic value) => HijriMonthStartOverride(
              month: HijriMonth(value['year'] as int, value['month'] as int),
              gregorianStartDate: GregorianDate.parse(value['start'] as String),
            ),
          ),
        ),
      );
      for (final dynamic sample in scenario['samples']! as List<dynamic>) {
        final components = sample['hijri'] as List<dynamic>;
        final expected = HijriDate(
          components[0] as int,
          components[1] as int,
          components[2] as int,
        );
        final civil = GregorianDate.parse(sample['gregorian'] as String);
        expect(engine.fromGregorian(civil), expected);
        expect(engine.toGregorian(expected), civil);
      }
    }
  });

  for (final entry in engines.entries) {
    final engine = entry.value;
    group(entry.key.name, () {
      test('every supported civil day round-trips without gaps', () {
        final first = engine.firstGregorianDate.epochDay;
        final last = engine.lastGregorianDate.epochDay;
        for (var day = first; day <= last; day++) {
          final gregorian = GregorianDate.fromEpochDay(day);
          final date = engine.fromGregorian(gregorian);
          if (engine.toGregorian(date) != gregorian) {
            fail('Round trip failed for ${entry.key} $gregorian $date');
          }
        }
      });
      test('every month has 29 or 30 days and rejects nonexistent days', () {
        for (var year = 1300; year <= 1600; year++) {
          for (var month = 1; month <= 12; month++) {
            final length = engine.daysInMonth(HijriMonth(year, month));
            expect(length, anyOf(29, 30));
            if (length == 29) {
              expect(engine.toGregorian(HijriDate(year, month, 30)), isNull);
            }
          }
        }
      });
      test('six-week grids include consecutive days at both range edges', () {
        for (final month in [
          HijriMonth(1300, 1),
          HijriMonth(1448, 9),
          HijriMonth(1600, 12),
        ]) {
          final grid = engine.monthGrid(month);
          expect(grid.days, hasLength(42));
          expect(grid.weeks, hasLength(6));
          expect(grid.weeks.every((week) => week.length == 7), isTrue);
          expect(
            grid.days
                .where((day) => day.monthPosition == HijriMonthPosition.current)
                .length,
            engine.daysInMonth(month),
          );
          for (var index = 1; index < grid.days.length; index++) {
            expect(
              grid.days[index].gregorianDate.epochDay -
                  grid.days[index - 1].gregorianDate.epochDay,
              1,
            );
          }
          expect(
            grid.days
                .where((day) => day.date.year < 1300 || day.date.year > 1600)
                .every((day) => !day.isWithinBounds),
            isTrue,
          );
        }
      });
      test('out-of-range conversions fail explicitly', () {
        expect(
          () => engine.fromGregorian(engine.firstGregorianDate.advanced(-1)),
          throwsRangeError,
        );
        expect(
          () => engine.fromGregorian(engine.lastGregorianDate.advanced(1)),
          throwsRangeError,
        );
        expect(
          () => engine.toGregorian(HijriDate(1299, 12, 30)),
          throwsRangeError,
        );
        expect(
          () => engine.toGregorian(HijriDate(1601, 1, 1)),
          throwsRangeError,
        );
      });
    });
  }

  test('known Umm al-Qura date', () {
    expect(
      engines[HijriCalendarSystem.ummAlQura]!.fromGregorian(
        GregorianDate(2024, 3, 11),
      ),
      HijriDate(1445, 9, 1),
    );
  });
  test('civil and tabular have distinct epochs', () {
    final date = HijriDate(1448, 9, 1);
    expect(
      engines[HijriCalendarSystem.civil]!.toGregorian(date)!.epochDay -
          engines[HijriCalendarSystem.tabular]!.toGregorian(date)!.epochDay,
      1,
    );
  });
  test(
    'component validation works in release mode and leap days are strict',
    () {
      expect(() => HijriDate(1448, 13, 1), throwsRangeError);
      expect(() => HijriDate(1448, 1, 0), throwsRangeError);
      expect(() => HijriMonth(0, 1), throwsRangeError);
      expect(() => GregorianDate(2025, 2, 29), throwsArgumentError);
      expect(
        GregorianDate.parse('2024-02-29').advanced(1),
        GregorianDate(2024, 3, 1),
      );
      expect(() => GregorianDate.parse('2024-2-29'), throwsFormatException);
      expect(HijriMonth(1448, 12).advanced(1), HijriMonth(1449, 1));
      expect(HijriMonth(1448, 1).advanced(-1), HijriMonth(1447, 12));
      expect(HijriDate(1448, 9, 1).toString(), '1448-09-01 AH');
    },
  );
  test('manual adjustment clamps and positive values display later dates', () {
    final configuration = HijriCalendarConfiguration(
      dayAdjustment: 10,
      firstWeekday: 0,
    );
    expect(configuration.dayAdjustment, 2);
    expect(configuration.firstWeekday, 1);
    final shifted = HijriCalendarEngine(configuration: configuration);
    final base = engines[HijriCalendarSystem.ummAlQura]!;
    final civil = GregorianDate(2026, 10, 18);
    expect(shifted.fromGregorian(civil), base.fromGregorian(civil.advanced(2)));
    expect(
      HijriCalendarConfiguration(
        dayAdjustment: -8,
        firstWeekday: 9,
      ).dayAdjustment,
      -2,
    );
    expect(HijriCalendarConfiguration(firstWeekday: 9).firstWeekday, 7);
  });
  test(
    'official timeline dominates manual adjustment and duplicate last wins',
    () {
      final month = HijriMonth(1448, 9);
      final civil = GregorianDate(2027, 2, 9);
      final configuration = HijriCalendarConfiguration(
        dayAdjustment: -2,
        monthStartOverrides: [
          HijriMonthStartOverride(
            month: month,
            gregorianStartDate: civil.advanced(5),
          ),
          HijriMonthStartOverride(month: month, gregorianStartDate: civil),
        ],
      );
      final engine = HijriCalendarEngine(configuration: configuration);
      expect(engine.toGregorian(month.firstDay), civil);
      expect(engine.fromGregorian(civil), month.firstDay);
      final other = HijriCalendarEngine(
        configuration: configuration.copyWith(dayAdjustment: 2),
      );
      expect(
        other.toGregorian(HijriDate(1448, 8, 10)),
        engine.toGregorian(HijriDate(1448, 8, 10)),
      );
      expect(
        configuration.withMonthStartOverride(month, null).monthStartOverrides,
        isEmpty,
      );
    },
  );
  test(
    'invalid and nonchronological authority intervals are rejected eagerly',
    () {
      final first = HijriMonth(1448, 9);
      final next = first.advanced(1);
      for (final length in [0, -1, 28, 31, 60]) {
        expect(
          () => HijriCalendarEngine(
            configuration: HijriCalendarConfiguration(
              monthStartOverrides: [
                HijriMonthStartOverride(
                  month: first,
                  gregorianStartDate: GregorianDate(2027, 2, 9),
                ),
                HijriMonthStartOverride(
                  month: next,
                  gregorianStartDate: GregorianDate(
                    2027,
                    2,
                    9,
                  ).advanced(length),
                ),
              ],
            ),
          ),
          throwsArgumentError,
        );
      }
    },
  );
  test('discontinuous nonconsecutive authority anchors are also rejected', () {
    expect(
      () => HijriCalendarEngine(
        configuration: HijriCalendarConfiguration(
          monthStartOverrides: [
            HijriMonthStartOverride(
              month: HijriMonth(1448, 9),
              gregorianStartDate: GregorianDate(2027, 2, 9),
            ),
            HijriMonthStartOverride(
              month: HijriMonth(1448, 11),
              gregorianStartDate: GregorianDate(2027, 4, 20),
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });
  test('bounds are inclusive and affect navigation', () {
    final first = HijriDate(1448, 9, 5);
    final last = HijriDate(1448, 9, 20);
    final engine = HijriCalendarEngine(
      configuration: HijriCalendarConfiguration(
        minimumDate: first,
        maximumDate: last,
      ),
    );
    expect(engine.isSelectable(first), isTrue);
    expect(engine.isSelectable(last), isTrue);
    expect(engine.isSelectable(HijriDate(1448, 9, 4)), isFalse);
    expect(engine.canDisplay(HijriMonth(1448, 8)), isFalse);
    expect(engine.canDisplay(HijriMonth(1448, 9)), isTrue);
    expect(engine.clampMonth(HijriMonth(1447, 1)), first.hijriMonth);
    expect(
      () => HijriCalendarConfiguration(minimumDate: last, maximumDate: first),
      throwsArgumentError,
    );
    final base = engines[HijriCalendarSystem.ummAlQura]!;
    final shortMonth = List.generate(
      12,
      (index) => HijriMonth(1448, index + 1),
    ).firstWhere((month) => base.daysInMonth(month) == 29);
    expect(
      () => HijriCalendarEngine(
        configuration: HijriCalendarConfiguration(
          minimumDate: HijriDate(1448, shortMonth.month, 30),
        ),
      ),
      throwsArgumentError,
    );
  });
  test('all first weekdays reorder grid and labels consistently', () {
    for (var first = 1; first <= 7; first++) {
      final engine = HijriCalendarEngine(
        configuration: HijriCalendarConfiguration(firstWeekday: first),
      );
      final grid = engine.monthGrid(HijriMonth(1448, 9));
      expect(grid.days.first.gregorianDate.weekday % 7 + 1, first);
      expect(
        engine.labels.weekdaySymbols(firstWeekday: first).first,
        ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'][first - 1],
      );
    }
  });
  test('time-zone projection distinguishes an instant from a civil day', () {
    final dubai = HijriCalendarEngine(
      configuration: HijriCalendarConfiguration(
        timeZoneIdentifier: 'Asia/Dubai',
      ),
    );
    final utc = engines[HijriCalendarSystem.ummAlQura]!;
    final instant = DateTime.utc(2026, 10, 18, 21);
    expect(
      dubai.fromDateTime(instant),
      utc.fromGregorian(GregorianDate(2026, 10, 19)),
    );
    expect(
      utc.fromDateTime(instant),
      utc.fromGregorian(GregorianDate(2026, 10, 18)),
    );
    final restored = dubai.toDateTime(dubai.fromDateTime(instant))!;
    expect(restored.hour, 12);
    expect(restored.timeZoneOffset, const Duration(hours: 4));
    expect(dubai.fromDateTime(restored), dubai.fromDateTime(instant));
    expect(
      () => HijriCalendarEngine(
        configuration: HijriCalendarConfiguration(
          timeZoneIdentifier: 'Unknown/Zone',
        ),
      ),
      throwsArgumentError,
    );
  });
  test('DST day arithmetic uses civil days instead of 24-hour durations', () {
    final engine = HijriCalendarEngine(
      configuration: HijriCalendarConfiguration(
        timeZoneIdentifier: 'America/New_York',
      ),
    );
    final before = GregorianDate(2026, 3, 7);
    final after = before.advanced(1);
    final first = engine.toDateTime(engine.fromGregorian(before))!;
    final second = engine.toDateTime(engine.fromGregorian(after))!;
    expect(second.difference(first), const Duration(hours: 23));
    expect(engine.fromDateTime(second), engine.fromGregorian(after));
  });
  test('a historically skipped civil day is not silently normalized', () {
    final engine = HijriCalendarEngine(
      configuration: HijriCalendarConfiguration(
        timeZoneIdentifier: 'Pacific/Apia',
      ),
    );
    final date = engine.fromGregorian(GregorianDate(2011, 12, 30));
    expect(() => engine.toDateTime(date), throwsStateError);
  });
  test('today follows the configured zone even with corrections', () {
    final engine = HijriCalendarEngine(
      configuration: HijriCalendarConfiguration(
        dayAdjustment: 1,
        timeZoneIdentifier: 'Asia/Dubai',
      ),
    );
    final instant = DateTime.utc(2026, 10, 18, 21);
    final today = engine.fromDateTime(instant);
    final grid = engine.monthGrid(today.hijriMonth, now: instant);
    expect(grid.days.where((day) => day.isToday).single.date, today);
  });
  test(
    'configuration and date JSON round trips preserve correction policy',
    () {
      final configuration = HijriCalendarConfiguration(
        calendarSystem: HijriCalendarSystem.tabular,
        localeIdentifier: 'ar_SA',
        timeZoneIdentifier: 'Asia/Dubai',
        firstWeekday: 7,
        dayAdjustment: 1,
        showsAdjacentMonthDates: false,
        minimumDate: HijriDate(1448, 9, 1),
        maximumDate: HijriDate(1448, 10, 29),
        layoutDirection: HijriLayoutDirection.rightToLeft,
        monthStartOverrides: [
          HijriMonthStartOverride(
            month: HijriMonth(1448, 9),
            gregorianStartDate: GregorianDate(2027, 2, 9),
          ),
        ],
      );
      final restored = HijriCalendarConfiguration.fromJson(
        jsonDecode(jsonEncode(configuration.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), configuration.toJson());
      expect(restored.copyWith(clearBounds: true).minimumDate, isNull);
      expect(restored.copyWith(clearMaximumDate: true).maximumDate, isNull);
      expect(
        HijriCalendarConfiguration.fromJson({}).calendarSystem,
        HijriCalendarSystem.ummAlQura,
      );
      final date = HijriDate(1448, 9, 1);
      expect(HijriDate.fromJson(date.toJson()), date);
      expect({date, HijriDate(1448, 9, 1)}, hasLength(1));
    },
  );
  test('Arabic labels and direction are independent of calculation system', () {
    final engine = HijriCalendarEngine(
      configuration: HijriCalendarConfiguration(
        localeIdentifier: 'ar_SA',
        calendarSystem: HijriCalendarSystem.civil,
      ),
    );
    expect(engine.configuration.isRightToLeft, isTrue);
    expect(engine.labels.monthTitle(HijriMonth(1448, 9)), contains('رمضان'));
    expect(
      engine.labels.dayLabel(HijriDate(1448, 9, 1), minimumDigits: 2),
      '٠١',
    );
    expect(
      engine.configuration
          .copyWith(layoutDirection: HijriLayoutDirection.leftToRight)
          .isRightToLeft,
      isFalse,
    );
    expect(
      HijriCalendarConfiguration(localeIdentifier: 'ur-PK').isRightToLeft,
      isTrue,
    );
    expect(HijriCalendarLabels('zz_ZZ').monthName(9), 'Ramadan');
  });
}
