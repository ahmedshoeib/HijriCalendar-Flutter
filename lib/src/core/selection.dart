import 'date.dart';

enum HijriSelectionMode { none, single, multiple, range }

final class HijriDateRange {
  HijriDateRange(HijriDate first, [HijriDate? second])
    : lowerBound = second != null && second.compareTo(first) < 0
          ? second
          : first,
      upperBound = second != null && second.compareTo(first) < 0
          ? first
          : second;
  final HijriDate lowerBound;
  final HijriDate? upperBound;
  bool contains(HijriDate date) => upperBound == null
      ? date == lowerBound
      : date.compareTo(lowerBound) >= 0 && date.compareTo(upperBound!) <= 0;
  Map<String, dynamic> toJson() => {
    'lowerBound': lowerBound.toJson(),
    'upperBound': upperBound?.toJson(),
  };
  factory HijriDateRange.fromJson(Map<String, dynamic> json) => HijriDateRange(
    HijriDate.fromJson(json['lowerBound'] as Map<String, dynamic>),
    json['upperBound'] == null
        ? null
        : HijriDate.fromJson(json['upperBound'] as Map<String, dynamic>),
  );
  @override
  bool operator ==(Object other) =>
      other is HijriDateRange &&
      lowerBound == other.lowerBound &&
      upperBound == other.upperBound;
  @override
  int get hashCode => Object.hash(lowerBound, upperBound);
}

/// An immutable selection suitable for a controller or external state storage.
final class HijriCalendarSelection {
  const HijriCalendarSelection.none()
    : mode = HijriSelectionMode.none,
      date = null,
      dates = const {},
      range = null;
  const HijriCalendarSelection.single([this.date])
    : mode = HijriSelectionMode.single,
      dates = const {},
      range = null;
  HijriCalendarSelection.multiple(Iterable<HijriDate> values)
    : mode = HijriSelectionMode.multiple,
      dates = Set.unmodifiable(values),
      date = null,
      range = null;
  const HijriCalendarSelection.range([this.range])
    : mode = HijriSelectionMode.range,
      dates = const {},
      date = null;

  factory HijriCalendarSelection.empty(HijriSelectionMode mode) =>
      switch (mode) {
        HijriSelectionMode.none => const HijriCalendarSelection.none(),
        HijriSelectionMode.single => const HijriCalendarSelection.single(),
        HijriSelectionMode.multiple => HijriCalendarSelection.multiple([]),
        HijriSelectionMode.range => const HijriCalendarSelection.range(),
      };

  factory HijriCalendarSelection.fromJson(Map<String, dynamic> json) =>
      switch (HijriSelectionMode.values.byName(json['mode'] as String)) {
        HijriSelectionMode.none => const HijriCalendarSelection.none(),
        HijriSelectionMode.single => HijriCalendarSelection.single(
          json['date'] == null
              ? null
              : HijriDate.fromJson(json['date'] as Map<String, dynamic>),
        ),
        HijriSelectionMode.multiple => HijriCalendarSelection.multiple(
          (json['dates'] as List<dynamic>).map(
            (value) => HijriDate.fromJson(value as Map<String, dynamic>),
          ),
        ),
        HijriSelectionMode.range => HijriCalendarSelection.range(
          json['range'] == null
              ? null
              : HijriDateRange.fromJson(json['range'] as Map<String, dynamic>),
        ),
      };

  final HijriSelectionMode mode;
  final HijriDate? date;
  final Set<HijriDate> dates;
  final HijriDateRange? range;

  bool contains(HijriDate value) => switch (mode) {
    HijriSelectionMode.none => false,
    HijriSelectionMode.single => date == value,
    HijriSelectionMode.multiple => dates.contains(value),
    HijriSelectionMode.range => range?.contains(value) ?? false,
  };

  /// Same tap rules as iOS: single toggles, multiple toggles, third range tap restarts.
  HijriCalendarSelection selecting(
    HijriDate value, {
    HijriSelectionMode? mode,
  }) {
    final resolved = mode ?? this.mode;
    final current = resolved == this.mode
        ? this
        : HijriCalendarSelection.empty(resolved);
    return switch (resolved) {
      HijriSelectionMode.none => const HijriCalendarSelection.none(),
      HijriSelectionMode.single => HijriCalendarSelection.single(
        current.date == value ? null : value,
      ),
      HijriSelectionMode.multiple => HijriCalendarSelection.multiple(
        current.dates.contains(value)
            ? ({...current.dates}..remove(value))
            : ({...current.dates}..add(value)),
      ),
      HijriSelectionMode.range => HijriCalendarSelection.range(
        current.range == null || current.range!.upperBound != null
            ? HijriDateRange(value)
            : HijriDateRange(current.range!.lowerBound, value),
      ),
    };
  }

  Map<String, dynamic> toJson() => switch (mode) {
    HijriSelectionMode.none => {'mode': mode.name},
    HijriSelectionMode.single => {'mode': mode.name, 'date': date?.toJson()},
    HijriSelectionMode.multiple => {
      'mode': mode.name,
      'dates': (dates.toList()..sort()).map((value) => value.toJson()).toList(),
    },
    HijriSelectionMode.range => {'mode': mode.name, 'range': range?.toJson()},
  };

  @override
  bool operator ==(Object other) =>
      other is HijriCalendarSelection &&
      mode == other.mode &&
      date == other.date &&
      range == other.range &&
      dates.length == other.dates.length &&
      dates.containsAll(other.dates);
  @override
  int get hashCode =>
      Object.hash(mode, date, range, Object.hashAllUnordered(dates));
}
