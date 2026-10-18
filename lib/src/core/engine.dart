import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'calendar_data.dart';
import 'configuration.dart';
import 'date.dart';
import 'localization.dart';

enum HijriMonthPosition { previous, current, next }

final class HijriCalendarDay {
  const HijriCalendarDay({
    required this.date,
    required this.gregorianDate,
    required this.monthPosition,
    required this.isToday,
    required this.isWithinBounds,
  });
  final HijriDate date;
  final GregorianDate gregorianDate;
  final HijriMonthPosition monthPosition;
  final bool isToday;
  final bool isWithinBounds;
}

final class HijriMonthGrid {
  HijriMonthGrid({
    required this.month,
    required Iterable<HijriCalendarDay> days,
  }) : days = List.unmodifiable(days);
  final HijriMonth month;
  final List<HijriCalendarDay> days;
  List<List<HijriCalendarDay>> get weeks =>
      List<List<HijriCalendarDay>>.unmodifiable(
        List<List<HijriCalendarDay>>.generate(
          6,
          (index) => List<HijriCalendarDay>.unmodifiable(
            days.sublist(index * 7, index * 7 + 7),
          ),
        ),
      );
}

/// Portable Foundation reference calculations with one coherent corrected timeline.
///
/// Public conversions support AH 1300...1600. Invalid lunar days return null;
/// unsupported years/days throw [RangeError]. Invalid authority timelines throw
/// [ArgumentError] on construction instead of producing ambiguous conversions.
final class HijriCalendarEngine {
  HijriCalendarEngine({HijriCalendarConfiguration? configuration})
    : configuration = configuration ?? HijriCalendarConfiguration() {
    _base = _baseStarts.putIfAbsent(
      this.configuration.calendarSystem,
      () => _expand(this.configuration.calendarSystem),
    );
    _starts = _correctedStarts();
    labels = HijriCalendarLabels(this.configuration.localeIdentifier);
    _location = _resolveLocation(this.configuration.timeZoneIdentifier);
    for (final bound in [
      this.configuration.minimumDate,
      this.configuration.maximumDate,
    ]) {
      if (bound != null && toGregorian(bound) == null) {
        throw ArgumentError(
          'Date bound does not exist in this calendar: $bound',
        );
      }
    }
  }

  static const minimumYear = 1300;
  static const maximumYear = 1600;
  static final Map<HijriCalendarSystem, List<int>> _baseStarts = {};
  static bool _timeZonesLoaded = false;
  final HijriCalendarConfiguration configuration;
  late final HijriCalendarLabels labels;
  late final List<int> _base;
  late final List<int> _starts;
  late final tz.Location? _location;

  static List<int> _expand(HijriCalendarSystem system) {
    final values = <int>[referenceYearStarts[system]!];
    for (final mask in referenceYearMasks[system]!) {
      for (var month = 0; month < 12; month++) {
        values.add(values.last + 29 + ((mask >> month) & 1));
      }
    }
    return List.unmodifiable(values);
  }

  static tz.Location? _resolveLocation(String identifier) {
    if (identifier == 'local') return null;
    if (identifier == 'UTC') return tz.UTC;
    if (!_timeZonesLoaded) {
      // Embedded Dart data works on native, JS, and WASM without an HTTP request.
      if (tz.timeZoneDatabase.locations.isEmpty) tz_data.initializeTimeZones();
      _timeZonesLoaded = true;
    }
    try {
      return tz.getLocation(identifier);
    } on tz.LocationNotFoundException {
      throw ArgumentError.value(
        identifier,
        'timeZoneIdentifier',
        'Unknown IANA time zone',
      );
    }
  }

  int _index(HijriMonth month, {bool padding = false}) {
    RangeError.checkValueInInterval(
      month.year,
      padding ? referenceFirstYear : minimumYear,
      padding ? referenceLastYear : maximumYear,
      'Hijri year',
    );
    return (month.year - referenceFirstYear) * 12 + month.month - 1;
  }

  HijriMonth _month(int index) =>
      HijriMonth(referenceFirstYear + index ~/ 12, index % 12 + 1);
  int get _firstPublic => (minimumYear - referenceFirstYear) * 12;
  int get _afterPublic => (maximumYear + 1 - referenceFirstYear) * 12;
  GregorianDate get firstGregorianDate =>
      GregorianDate.fromEpochDay(_starts[_firstPublic]);
  GregorianDate get lastGregorianDate =>
      GregorianDate.fromEpochDay(_starts[_afterPublic] - 1);

  List<int> _correctedStarts() {
    final byMonth = <int, int>{};
    for (final anchor in configuration.monthStartOverrides) {
      byMonth[_index(anchor.month)] = anchor.gregorianStartDate.epochDay;
    }
    if (byMonth.isEmpty) {
      return List.unmodifiable(
        _base.map((day) => day - configuration.dayAdjustment),
      );
    }
    final anchors = byMonth.keys.toList()..sort();
    var anchorPosition = 0;
    final result = <int>[];
    for (var index = 0; index < _base.length; index++) {
      while (anchorPosition + 1 < anchors.length &&
          anchors[anchorPosition + 1] <= index) {
        anchorPosition++;
      }
      final anchor = anchors[anchorPosition];
      result.add(byMonth[anchor]! + _base[index] - _base[anchor]);
    }
    for (var index = 0; index < result.length - 1; index++) {
      final length = result[index + 1] - result[index];
      if (length < 29 || length > 30) {
        throw ArgumentError(
          'Official starts create a $length-day month at ${_month(index)}; every month must have 29 or 30 days.',
        );
      }
    }
    return List.unmodifiable(result);
  }

  int daysInMonth(HijriMonth month) {
    final index = _index(month);
    return _starts[index + 1] - _starts[index];
  }

  /// Resolves a civil day, without applying the configured time zone again.
  HijriDate fromGregorian(GregorianDate date) => _fromDay(date.epochDay);

  HijriDate _fromDay(int day, {bool padding = false}) {
    final first = padding ? 0 : _firstPublic;
    final end = padding ? _starts.length - 1 : _afterPublic;
    if (day < _starts[first] || day >= _starts[end]) {
      throw RangeError(
        'Gregorian day ${GregorianDate.fromEpochDay(day)} is outside the supported calendar range.',
      );
    }
    var low = first;
    var high = end;
    while (low + 1 < high) {
      final middle = (low + high) ~/ 2;
      if (_starts[middle] <= day) {
        low = middle;
      } else {
        high = middle;
      }
    }
    final month = _month(low);
    return HijriDate(month.year, month.month, day - _starts[low] + 1);
  }

  /// Returns null for a nonexistent lunar day, such as day 30 of a 29-day month.
  GregorianDate? toGregorian(HijriDate date) {
    final index = _index(date.hijriMonth);
    if (date.day > _starts[index + 1] - _starts[index]) return null;
    return GregorianDate.fromEpochDay(_starts[index] + date.day - 1);
  }

  /// Projects an instant into the configured zone before reading its civil day.
  GregorianDate civilDay(DateTime instant) => GregorianDate.fromDateTime(
    _location == null
        ? instant.toLocal()
        : tz.TZDateTime.from(instant, _location),
  );
  HijriDate fromDateTime(DateTime instant) => fromGregorian(civilDay(instant));

  /// Noon on the resolved Gregorian day, in the configured zone.
  ///
  /// Rejects a civil day skipped by a historical time-zone change.
  DateTime? toDateTime(HijriDate date) {
    final day = toGregorian(date);
    if (day == null) return null;
    final result = _location == null
        ? DateTime(day.year, day.month, day.day, 12)
        : tz.TZDateTime(_location, day.year, day.month, day.day, 12);
    if (GregorianDate.fromDateTime(result) != day) {
      throw StateError(
        'The civil day $day does not exist in ${configuration.timeZoneIdentifier}.',
      );
    }
    return result;
  }

  bool isSupported(HijriDate date) =>
      date.year >= minimumYear && date.year <= maximumYear;
  bool isSelectable(HijriDate date) =>
      isSupported(date) &&
      configuration.contains(date) &&
      toGregorian(date) != null;

  /// Whether a month intersects the inclusive bounds and the public date range.
  bool canDisplay(HijriMonth month) {
    if (month.year < minimumYear || month.year > maximumYear) return false;
    final first = month.firstDay;
    final last = HijriDate(month.year, month.month, daysInMonth(month));
    return (configuration.minimumDate == null ||
            last.compareTo(configuration.minimumDate!) >= 0) &&
        (configuration.maximumDate == null ||
            first.compareTo(configuration.maximumDate!) <= 0);
  }

  HijriMonth clampMonth(HijriMonth month) {
    var result = month;
    final minimum =
        configuration.minimumDate?.hijriMonth ?? HijriMonth(minimumYear, 1);
    final maximum =
        configuration.maximumDate?.hijriMonth ?? HijriMonth(maximumYear, 12);
    if (result.compareTo(minimum) < 0) result = minimum;
    if (result.compareTo(maximum) > 0) result = maximum;
    return result;
  }

  HijriMonth todayMonth({DateTime? now}) {
    final day = civilDay(now ?? DateTime.now());
    if (day.compareTo(firstGregorianDate) < 0) {
      return clampMonth(HijriMonth(minimumYear, 1));
    }
    if (day.compareTo(lastGregorianDate) > 0) {
      return clampMonth(HijriMonth(maximumYear, 12));
    }
    return clampMonth(fromGregorian(day).hijriMonth);
  }

  HijriMonthGrid monthGrid(HijriMonth month, {DateTime? now}) {
    final index = _index(month);
    final start = GregorianDate.fromEpochDay(_starts[index]);
    final foundationWeekday = start.weekday % 7 + 1;
    final leading = (foundationWeekday - configuration.firstWeekday + 7) % 7;
    final today = civilDay(now ?? DateTime.now());
    return HijriMonthGrid(
      month: month,
      days: List.generate(42, (offset) {
        final gregorian = start.advanced(offset - leading);
        final date = _fromDay(gregorian.epochDay, padding: true);
        final order = date.hijriMonth.compareTo(month);
        return HijriCalendarDay(
          date: date,
          gregorianDate: gregorian,
          monthPosition: order < 0
              ? HijriMonthPosition.previous
              : order > 0
              ? HijriMonthPosition.next
              : HijriMonthPosition.current,
          isToday: gregorian == today,
          isWithinBounds: isSelectable(date),
        );
      }),
    );
  }
}
