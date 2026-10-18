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
}
