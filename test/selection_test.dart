import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri_calendar_flutter/hijri_calendar_core.dart';

void main() {
  final first = HijriDate(1448, 9, 5);
  final second = HijriDate(1448, 9, 10);
  final third = HijriDate(1448, 9, 15);
  test('read-only never selects', () {
    expect(
      const HijriCalendarSelection.none().selecting(first),
      const HijriCalendarSelection.none(),
    );
  });
  test('single selection toggles off and replaces another day', () {
    final selected = const HijriCalendarSelection.single().selecting(first);
    expect(selected.date, first);
    expect(selected.selecting(first).date, isNull);
    expect(selected.selecting(second).date, second);
  });
  test('multiple selection toggles independent immutable dates', () {
    final original = HijriCalendarSelection.multiple([first]);
    final next = original.selecting(second);
    expect(next.dates, {first, second});
    expect(next.selecting(first).dates, {second});
    expect(original.dates, {first});
    expect(() => next.dates.add(third), throwsUnsupportedError);
  });
  test('range normalizes reverse input and third tap starts again', () {
    final partial = const HijriCalendarSelection.range().selecting(second);
    expect(partial.range!.upperBound, isNull);
    expect(partial.contains(first), isFalse);
    final completed = partial.selecting(first);
    expect(completed.range!.lowerBound, first);
    expect(completed.range!.upperBound, second);
    expect(completed.contains(HijriDate(1448, 9, 8)), isTrue);
    expect(completed.selecting(third).range!.lowerBound, third);
    expect(completed.selecting(third).range!.upperBound, isNull);
  });
  test('same-day range completes and mismatched reducers recover', () {
    final range = const HijriCalendarSelection.range()
        .selecting(first)
        .selecting(first);
    expect(range.range!.upperBound, first);
    expect(
      const HijriCalendarSelection.none()
          .selecting(first, mode: HijriSelectionMode.multiple)
          .dates,
      {first},
    );
  });
  test('selection equality, hashing, and JSON are stable for every mode', () {
    final selections = [
      const HijriCalendarSelection.none(),
      const HijriCalendarSelection.single(),
      HijriCalendarSelection.single(first),
      HijriCalendarSelection.multiple([first, second]),
      const HijriCalendarSelection.range(),
      HijriCalendarSelection.range(HijriDateRange(first)),
      HijriCalendarSelection.range(HijriDateRange(second, first)),
    ];
    for (final selection in selections) {
      final restored = HijriCalendarSelection.fromJson(
        jsonDecode(jsonEncode(selection.toJson())) as Map<String, dynamic>,
      );
      expect(restored, selection);
      expect(restored.hashCode, selection.hashCode);
    }
    expect(
      HijriCalendarSelection.multiple([second, first]),
      HijriCalendarSelection.multiple([first, second]),
    );
  });
}
