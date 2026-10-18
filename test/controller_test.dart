import 'package:flutter_test/flutter_test.dart';
import 'package:hijri_calendar_flutter/hijri_calendar_flutter.dart';

void main() {
  late HijriCalendarController controller;
  setUp(
    () => controller = HijriCalendarController(
      displayedMonth: HijriMonth(1448, 9),
      clock: () => DateTime.utc(2026, 10, 18),
    ),
  );
  tearDown(() => controller.dispose());

  test('programmatic navigation and selection notify once per change', () {
    var changes = 0;
    controller.addListener(() => changes++);
    controller.nextMonth();
    expect(controller.displayedMonth, HijriMonth(1448, 10));
    controller.previousMonth();
    expect(controller.displayedMonth, HijriMonth(1448, 9));
    final date = HijriDate(1448, 9, 5);
    controller.select(date);
    expect(controller.selection.date, date);
    controller.select(date);
    expect(controller.selection.date, isNull);
    expect(changes, 4);
  });
  test('mode changes reset mismatched state', () {
    controller.select(HijriDate(1448, 9, 5));
    controller.selectionMode = HijriSelectionMode.multiple;
    expect(controller.selection.dates, isEmpty);
    controller.select(HijriDate(1448, 9, 5));
    expect(controller.selection.dates, hasLength(1));
    controller.selectionMode = HijriSelectionMode.none;
    controller.select(HijriDate(1448, 9, 10));
    expect(controller.selection, const HijriCalendarSelection.none());
  });
  test('bounds constrain navigation and prune selection', () {
    controller.select(HijriDate(1448, 9, 1));
    controller.configuration = controller.configuration.copyWith(
      minimumDate: HijriDate(1448, 9, 5),
      maximumDate: HijriDate(1448, 9, 20),
    );
    expect(controller.selection.date, isNull);
    expect(controller.canGoBack, isFalse);
    expect(controller.canGoForward, isFalse);
    expect(controller.nextMonth(), isFalse);
    controller.select(HijriDate(1448, 9, 4));
    expect(controller.selection.date, isNull);
    controller.select(HijriDate(1448, 9, 5));
    expect(controller.selection.date, HijriDate(1448, 9, 5));
  });
  test('invalid configuration cannot partially mutate a controller', () {
    final old = controller.configuration;
    expect(
      () => controller.configuration = old.copyWith(
        timeZoneIdentifier: 'Invalid/Zone',
      ),
      throwsArgumentError,
    );
    expect(controller.configuration, same(old));
  });
  test('system changes clear selection and use the new system for today', () {
    controller.select(HijriDate(1448, 9, 1));
    controller.configuration = controller.configuration.copyWith(
      calendarSystem: HijriCalendarSystem.civil,
      timeZoneIdentifier: 'UTC',
    );
    expect(controller.selection.date, isNull);
    expect(
      controller.displayedMonth,
      controller.engine.fromDateTime(DateTime.utc(2026, 10, 18)).hijriMonth,
    );
  });
  test('range edges stop navigation and complete grids remain available', () {
    controller.display(HijriMonth(1300, 1));
    expect(controller.canGoBack, isFalse);
    expect(controller.previousMonth(), isFalse);
    expect(controller.grid.days, hasLength(42));
    controller.display(HijriMonth(1600, 12));
    expect(controller.canGoForward, isFalse);
    expect(controller.nextMonth(), isFalse);
  });
  test('date selection does not silently change displayed month', () {
    controller.select(HijriDate(1448, 10, 2));
    expect(controller.displayedMonth, HijriMonth(1448, 9));
    expect(controller.selection.date, HijriDate(1448, 10, 2));
  });
}
