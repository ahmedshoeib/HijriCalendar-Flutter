import 'calendar_data.dart';
import 'date.dart';

enum HijriLayoutDirection { automatic, leftToRight, rightToLeft }

/// An authority's exact Gregorian civil day for the start of a Hijri month.
final class HijriMonthStartOverride {
  const HijriMonthStartOverride({
    required this.month,
    required this.gregorianStartDate,
  });
  factory HijriMonthStartOverride.fromJson(Map<String, dynamic> json) =>
      HijriMonthStartOverride(
        month: HijriMonth.fromJson(json['month'] as Map<String, dynamic>),
        gregorianStartDate: GregorianDate.parse(
          json['gregorianStartDate'] as String,
        ),
      );
  final HijriMonth month;
  final GregorianDate gregorianStartDate;
  Map<String, dynamic> toJson() => {
    'month': month.toJson(),
    'gregorianStartDate': gregorianStartDate.toString(),
  };
}

/// Immutable calendar policy. Corrections are instance-owned and offline.
final class HijriCalendarConfiguration {
  HijriCalendarConfiguration({
    this.calendarSystem = HijriCalendarSystem.ummAlQura,
    this.localeIdentifier = 'en',
    this.timeZoneIdentifier = 'local',
    int firstWeekday = 1,
    int dayAdjustment = 0,
    Iterable<HijriMonthStartOverride> monthStartOverrides = const [],
    this.minimumDate,
    this.maximumDate,
    this.showsAdjacentMonthDates = true,
    this.layoutDirection = HijriLayoutDirection.automatic,
  }) : firstWeekday = firstWeekday.clamp(1, 7),
       dayAdjustment = dayAdjustment.clamp(-2, 2),
       monthStartOverrides = List.unmodifiable(monthStartOverrides) {
    if (minimumDate != null &&
        maximumDate != null &&
        minimumDate!.compareTo(maximumDate!) > 0) {
      throw ArgumentError('minimumDate must not be later than maximumDate');
    }
  }

  factory HijriCalendarConfiguration.fromJson(
    Map<String, dynamic> json,
  ) => HijriCalendarConfiguration(
    calendarSystem: HijriCalendarSystem.values.byName(
      json['calendarSystem'] as String? ?? 'ummAlQura',
    ),
    localeIdentifier: json['localeIdentifier'] as String? ?? 'en',
    timeZoneIdentifier: json['timeZoneIdentifier'] as String? ?? 'local',
    firstWeekday: json['firstWeekday'] as int? ?? 1,
    dayAdjustment: json['dayAdjustment'] as int? ?? 0,
    monthStartOverrides: (json['monthStartOverrides'] as List<dynamic>? ?? [])
        .map(
          (value) =>
              HijriMonthStartOverride.fromJson(value as Map<String, dynamic>),
        ),
    minimumDate: json['minimumDate'] == null
        ? null
        : HijriDate.fromJson(json['minimumDate'] as Map<String, dynamic>),
    maximumDate: json['maximumDate'] == null
        ? null
        : HijriDate.fromJson(json['maximumDate'] as Map<String, dynamic>),
    showsAdjacentMonthDates: json['showsAdjacentMonthDates'] as bool? ?? true,
    layoutDirection: HijriLayoutDirection.values.byName(
      json['layoutDirection'] as String? ?? 'automatic',
    ),
  );

  final HijriCalendarSystem calendarSystem;
  final String localeIdentifier;

  /// `local`, `UTC`, or an IANA identifier such as `Asia/Dubai`.
  final String timeZoneIdentifier;

  /// Foundation-compatible numbering: Sunday = 1 through Saturday = 7.
  final int firstWeekday;

  /// Positive values show a later Hijri day; clamped to -2...2.
  final int dayAdjustment;
  final List<HijriMonthStartOverride> monthStartOverrides;
  final HijriDate? minimumDate;
  final HijriDate? maximumDate;
  final bool showsAdjacentMonthDates;
  final HijriLayoutDirection layoutDirection;

  bool get isRightToLeft {
    if (layoutDirection != HijriLayoutDirection.automatic) {
      return layoutDirection == HijriLayoutDirection.rightToLeft;
    }
    final language = localeIdentifier.toLowerCase().split(RegExp('[_-]')).first;
    return const {
      'ar',
      'arc',
      'ckb',
      'dv',
      'fa',
      'he',
      'ku',
      'nqo',
      'ps',
      'sd',
      'syr',
      'ug',
      'ur',
      'yi',
    }.contains(language);
  }

  bool contains(HijriDate date) =>
      (minimumDate == null || date.compareTo(minimumDate!) >= 0) &&
      (maximumDate == null || date.compareTo(maximumDate!) <= 0);

  /// Set [clearBounds] to remove both bounds, or use the individual clear flags.
  HijriCalendarConfiguration copyWith({
    HijriCalendarSystem? calendarSystem,
    String? localeIdentifier,
    String? timeZoneIdentifier,
    int? firstWeekday,
    int? dayAdjustment,
    Iterable<HijriMonthStartOverride>? monthStartOverrides,
    HijriDate? minimumDate,
    HijriDate? maximumDate,
    bool clearBounds = false,
    bool clearMinimumDate = false,
    bool clearMaximumDate = false,
    bool? showsAdjacentMonthDates,
    HijriLayoutDirection? layoutDirection,
  }) => HijriCalendarConfiguration(
    calendarSystem: calendarSystem ?? this.calendarSystem,
    localeIdentifier: localeIdentifier ?? this.localeIdentifier,
    timeZoneIdentifier: timeZoneIdentifier ?? this.timeZoneIdentifier,
    firstWeekday: firstWeekday ?? this.firstWeekday,
    dayAdjustment: dayAdjustment ?? this.dayAdjustment,
    monthStartOverrides: monthStartOverrides ?? this.monthStartOverrides,
    minimumDate: clearBounds || clearMinimumDate
        ? null
        : minimumDate ?? this.minimumDate,
    maximumDate: clearBounds || clearMaximumDate
        ? null
        : maximumDate ?? this.maximumDate,
    showsAdjacentMonthDates:
        showsAdjacentMonthDates ?? this.showsAdjacentMonthDates,
    layoutDirection: layoutDirection ?? this.layoutDirection,
  );

  /// Adds, replaces, or removes one official start. Pass null to remove it.
  HijriCalendarConfiguration withMonthStartOverride(
    HijriMonth month,
    GregorianDate? date,
  ) => copyWith(
    monthStartOverrides: [
      ...monthStartOverrides.where((value) => value.month != month),
      if (date != null)
        HijriMonthStartOverride(month: month, gregorianStartDate: date),
    ],
  );

  Map<String, dynamic> toJson() => {
    'calendarSystem': calendarSystem.name,
    'localeIdentifier': localeIdentifier,
    'timeZoneIdentifier': timeZoneIdentifier,
    'firstWeekday': firstWeekday,
    'dayAdjustment': dayAdjustment,
    'monthStartOverrides': monthStartOverrides
        .map((value) => value.toJson())
        .toList(),
    'minimumDate': minimumDate?.toJson(),
    'maximumDate': maximumDate?.toJson(),
    'showsAdjacentMonthDates': showsAdjacentMonthDates,
    'layoutDirection': layoutDirection.name,
  };
}
