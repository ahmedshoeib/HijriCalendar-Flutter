import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri_calendar_example/main.dart';

void main() {
  testWidgets('showcase starts, switches language and theme', (tester) async {
    await tester.pumpWidget(const CalendarShowcase());
    await tester.pumpAndSettle();
    expect(find.text('Hijri Calendar'), findsOneWidget);
    expect(find.text('Umm al-Qura'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('language-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('التقويم الهجري'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'desktop showcase displays the calendar and settings side by side',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const CalendarShowcase());
      await tester.pumpAndSettle();
      final calendar = tester.getTopLeft(
        find.byKey(const ValueKey('hijri-month-title')),
      );
      final settings = tester.getTopLeft(find.text('Calendar settings'));
      expect(settings.dx, greaterThan(calendar.dx));
      expect(settings.dy, lessThan(calendar.dy));
      await tester.tap(find.byKey(const ValueKey('language-toggle')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('phone showcase remains usable at 360 logical pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CalendarShowcase());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
