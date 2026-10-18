import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri_calendar_flutter/hijri_calendar_flutter.dart';

Finder day(int value, {int month = 9, int year = 1448}) =>
    find.byKey(ValueKey('hijri-day-$year-$month-$value'));

Widget host(Widget child, {double width = 440, double scale = 1}) =>
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    );

void main() {
  late HijriCalendarController controller;
  setUp(
    () => controller = HijriCalendarController(
      displayedMonth: HijriMonth(1448, 9),
      clock: () => DateTime.utc(2027, 2, 15),
    ),
  );
  tearDown(() => controller.dispose());

  testWidgets('tap toggles single selection and calls user callbacks', (
    tester,
  ) async {
    final changes = <HijriCalendarSelection>[];
    final taps = <HijriDate>[];
    await tester.pumpWidget(
      host(
        HijriCalendar(
          controller: controller,
          onSelectionChanged: changes.add,
          onDateTap: taps.add,
        ),
      ),
    );
    await tester.tap(day(5));
    await tester.pump();
    expect(controller.selection.date, HijriDate(1448, 9, 5));
    await tester.tap(day(5));
    await tester.pump();
    expect(controller.selection.date, isNull);
    expect(changes, hasLength(2));
    expect(taps, [HijriDate(1448, 9, 5), HijriDate(1448, 9, 5)]);
  });
  testWidgets('multiple, range, and read-only use the same grid', (
    tester,
  ) async {
    await tester.pumpWidget(host(HijriCalendar(controller: controller)));
    controller.selectionMode = HijriSelectionMode.multiple;
    await tester.pump();
    await tester.tap(day(5));
    await tester.tap(day(10));
    expect(controller.selection.dates, hasLength(2));
    controller.selectionMode = HijriSelectionMode.range;
    await tester.pump();
    await tester.tap(day(10));
    await tester.tap(day(5));
    expect(
      controller.selection.range,
      HijriDateRange(HijriDate(1448, 9, 5), HijriDate(1448, 9, 10)),
    );
    controller.selectionMode = HijriSelectionMode.none;
    await tester.pump();
    await tester.tap(day(15));
    expect(controller.selection, const HijriCalendarSelection.none());
  });
  testWidgets('disabled decorations and bounds block taps', (tester) async {
    controller.configuration = controller.configuration.copyWith(
      minimumDate: HijriDate(1448, 9, 3),
      maximumDate: HijriDate(1448, 9, 20),
    );
    await tester.pumpWidget(
      host(
        HijriCalendar(
          controller: controller,
          dayDecoration: (date) =>
              HijriCalendarDayDecoration(isEnabled: date.day != 5),
        ),
      ),
    );
    await tester.tap(day(1));
    await tester.tap(day(5));
    await tester.pump();
    expect(controller.selection.date, isNull);
    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('hijri-next')),
    );
    expect(button.onPressed, isNull);
  });
  testWidgets(
    'Arabic RTL and custom labels retain complete accessibility labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      controller.configuration = controller.configuration.copyWith(
        localeIdentifier: 'ar_SA',
        firstWeekday: 7,
      );
      await tester.pumpWidget(
        host(
          HijriCalendar(
            controller: controller,
            minimumDayLabelDigits: 2,
            dayDecoration: (date) => date.day == 5
                ? const HijriCalendarDayDecoration(
                    label: 'حدث',
                    accessibilityLabel: 'موعد خاص',
                  )
                : null,
          ),
        ),
      );
      expect(find.text('رمضان ١٤٤٨'), findsOneWidget);
      expect(
        find.descendant(of: day(1), matching: find.text('٠١')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: day(5), matching: find.text('حدث')),
        findsOneWidget,
      );
      expect(tester.getSemantics(day(5)).label, 'موعد خاص');
      final context = tester.element(day(5));
      expect(Directionality.of(context), TextDirection.rtl);
      semantics.dispose();
    },
  );
  testWidgets('selected and disabled semantic states are exposed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        HijriCalendar(
          controller: controller,
          dayDecoration: (date) =>
              HijriCalendarDayDecoration(isEnabled: date.day != 6),
        ),
      ),
    );
    await tester.tap(day(5));
    await tester.pump();
    expect(
      tester.getSemantics(day(5)).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(day(6)).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    expect(tester.getSemantics(day(5)).label, contains('Ramadan'));
    semantics.dispose();
  });
  testWidgets('navigation callbacks include controller changes', (
    tester,
  ) async {
    final months = <HijriMonth>[];
    await tester.pumpWidget(
      host(
        HijriCalendar(
          controller: controller,
          onDisplayedMonthChanged: months.add,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('hijri-next')));
    await tester.pump();
    expect(controller.displayedMonth, HijriMonth(1448, 10));
    controller.previousMonth();
    await tester.pump();
    expect(months, [HijriMonth(1448, 10), HijriMonth(1448, 9)]);
  });
  testWidgets('swipes advance in the locale direction', (tester) async {
    await tester.pumpWidget(host(HijriCalendar(controller: controller)));
    await tester.fling(find.byType(HijriCalendar), const Offset(-250, 0), 700);
    await tester.pumpAndSettle();
    expect(controller.displayedMonth, HijriMonth(1448, 10));
    controller.configuration = controller.configuration.copyWith(
      localeIdentifier: 'ar',
    );
    await tester.pump();
    await tester.fling(find.byType(HijriCalendar), const Offset(250, 0), 700);
    await tester.pumpAndSettle();
    expect(controller.displayedMonth, HijriMonth(1448, 11));
  });
  testWidgets(
    'arrow keys move focus, Enter selects, and PageDown changes month',
    (tester) async {
      await tester.pumpWidget(host(HijriCalendar(controller: controller)));
      await tester.tap(day(5));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.selection.date, HijriDate(1448, 9, 6));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.displayedMonth, HijriMonth(1448, 10));
      expect(controller.selection.date, HijriDate(1448, 10, 6));
    },
  );
  testWidgets(
    'keyboard uses the displayed grid after programmatic navigation',
    (tester) async {
      await tester.pumpWidget(host(HijriCalendar(controller: controller)));
      await tester.tap(day(5));
      await tester.pump();
      controller.nextMonth();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.displayedMonth, HijriMonth(1448, 10));
      expect(controller.selection.date!.hijriMonth, HijriMonth(1448, 10));
    },
  );
  testWidgets('keyboard skips disabled dates and respects RTL', (tester) async {
    controller.configuration = controller.configuration.copyWith(
      localeIdentifier: 'ar',
    );
    await tester.pumpWidget(
      host(
        HijriCalendar(
          controller: controller,
          dayDecoration: (date) =>
              HijriCalendarDayDecoration(isEnabled: date.day != 6),
        ),
      ),
    );
    await tester.tap(day(5));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.selection.date, HijriDate(1448, 9, 7));
  });
  testWidgets(
    'adjacent dates can be hidden and custom builders keep interaction',
    (tester) async {
      controller.configuration = controller.configuration.copyWith(
        showsAdjacentMonthDates: false,
      );
      await tester.pumpWidget(
        host(
          HijriCalendar(
            controller: controller,
            dayBuilder: (context, details) =>
                Center(child: Text('D${details.date.day}')),
          ),
        ),
      );
      expect(find.text('D5'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.key.toString().contains('hijri-day-1448-8-'),
        ),
        findsNothing,
      );
      await tester.tap(day(5));
      expect(controller.selection.date, HijriDate(1448, 9, 5));
    },
  );
  testWidgets(
    'range boundaries render full grids with disabled padding dates',
    (tester) async {
      controller.display(HijriMonth(1300, 1));
      await tester.pumpWidget(
        host(
          HijriCalendar(
            controller: controller,
            dayDecoration: (date) {
              controller.engine.toGregorian(date);
              return null;
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      controller.display(HijriMonth(1600, 12));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('narrow layouts and large text avoid overflow', (tester) async {
    for (final width in [280.0, 400.0, 900.0]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        await tester.pumpWidget(
          host(
            HijriCalendar(controller: controller),
            width: width,
            scale: scale,
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'width=$width scale=$scale',
        );
      }
    }
  });
  testWidgets(
    'widget-owned state survives rebuild and responds to configuration',
    (tester) async {
      HijriCalendarConfiguration configuration = HijriCalendarConfiguration();
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return HijriCalendar(
                configuration: configuration,
                initialDisplayedMonth: HijriMonth(1448, 9),
              );
            },
          ),
        ),
      );
      await tester.tap(day(5));
      await tester.pump();
      update(
        () => configuration = configuration.copyWith(localeIdentifier: 'ar'),
      );
      await tester.pump();
      expect(find.text('رمضان ١٤٤٨'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'replacing and detaching an external controller removes listeners',
    (tester) async {
      final replacement = HijriCalendarController(
        displayedMonth: HijriMonth(1448, 10),
      );
      await tester.pumpWidget(host(HijriCalendar(controller: controller)));
      await tester.pumpWidget(host(HijriCalendar(controller: replacement)));
      controller.nextMonth();
      await tester.pump();
      expect(find.text('Shawwal 1448'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      replacement.nextMonth();
      replacement.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
