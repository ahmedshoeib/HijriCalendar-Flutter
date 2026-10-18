import 'package:flutter/material.dart';

import '../../hijri_calendar_core.dart';

/// Theme overrides. Unspecified colors follow the enclosing Material theme.
@immutable
class HijriCalendarStyle {
  const HijriCalendarStyle({
    this.backgroundColor,
    this.textColor,
    this.adjacentTextColor,
    this.selectionColor,
    this.selectedTextColor,
    this.rangeColor,
    this.todayColor,
    this.eventColor,
    this.headerTextStyle,
    this.dayTextStyle,
    this.weekdayTextStyle,
    this.dayCornerRadius = 12,
    this.cellHeight = 48,
    this.cellSpacing = 2,
    this.padding = const EdgeInsets.all(12),
  }) : assert(cellHeight >= 40),
       assert(cellSpacing >= 0),
       assert(dayCornerRadius >= 0);
  final Color? backgroundColor;
  final Color? textColor;
  final Color? adjacentTextColor;
  final Color? selectionColor;
  final Color? selectedTextColor;
  final Color? rangeColor;
  final Color? todayColor;
  final Color? eventColor;
  final TextStyle? headerTextStyle;
  final TextStyle? dayTextStyle;
  final TextStyle? weekdayTextStyle;
  final double dayCornerRadius;
  final double cellHeight;
  final double cellSpacing;
  final EdgeInsetsGeometry padding;
}

/// Data-driven decoration for a day; a disabled day still has accessible text.
@immutable
class HijriCalendarDayDecoration {
  const HijriCalendarDayDecoration({
    this.label,
    this.textColor,
    this.backgroundColor,
    this.eventColor,
    this.hasEvent = false,
    this.isEnabled = true,
    this.accessibilityLabel,
    this.tooltip,
  });
  final String? label;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? eventColor;
  final bool hasEvent;
  final bool isEnabled;
  final String? accessibilityLabel;
  final String? tooltip;
}

/// State passed to a custom cell builder. Interaction and semantics are retained.
@immutable
class HijriCalendarDayDetails {
  const HijriCalendarDayDetails({
    required this.day,
    required this.isSelected,
    required this.isRangeEndpoint,
    required this.isEnabled,
    required this.label,
    required this.decoration,
  });
  final HijriCalendarDay day;
  HijriDate get date => day.date;
  final bool isSelected;
  final bool isRangeEndpoint;
  final bool isEnabled;
  final String label;
  final HijriCalendarDayDecoration? decoration;
}
