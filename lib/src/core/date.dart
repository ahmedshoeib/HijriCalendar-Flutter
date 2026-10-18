/// A Hijri civil date. Its calculation system belongs to the calendar engine.
final class HijriDate implements Comparable<HijriDate> {
  HijriDate(this.year, this.month, this.day) {
    if (year < 1) throw RangeError.value(year, 'year', 'Must be positive');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    RangeError.checkValueInInterval(day, 1, 30, 'day');
  }

  factory HijriDate.fromJson(Map<String, dynamic> json) =>
      HijriDate(json['year'] as int, json['month'] as int, json['day'] as int);

  final int year;
  final int month;
  final int day;
  HijriMonth get hijriMonth => HijriMonth(year, month);

  Map<String, dynamic> toJson() => {'year': year, 'month': month, 'day': day};

  @override
  int compareTo(HijriDate other) {
    final monthOrder = hijriMonth.compareTo(other.hijriMonth);
    return monthOrder != 0 ? monthOrder : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;
  @override
  int get hashCode => Object.hash(year, month, day);
  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)} AH';
}

/// A Hijri month with calendar-independent component arithmetic.
final class HijriMonth implements Comparable<HijriMonth> {
  HijriMonth(this.year, this.month) {
    if (year < 1) throw RangeError.value(year, 'year', 'Must be positive');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
  }
  factory HijriMonth.fromJson(Map<String, dynamic> json) =>
      HijriMonth(json['year'] as int, json['month'] as int);
  final int year;
  final int month;
  int get ordinal => year * 12 + month - 1;
  HijriDate get firstDay => HijriDate(year, month, 1);

  HijriMonth advanced(int months) {
    final value = ordinal + months;
    return HijriMonth(value ~/ 12, value % 12 + 1);
  }

  Map<String, dynamic> toJson() => {'year': year, 'month': month};
  @override
  int compareTo(HijriMonth other) => ordinal.compareTo(other.ordinal);
  @override
  bool operator ==(Object other) =>
      other is HijriMonth && ordinal == other.ordinal;
  @override
  int get hashCode => ordinal.hashCode;
  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)} AH';
}

/// A Gregorian civil day, deliberately independent of an instant or time zone.
///
/// Use the engine's `fromDateTime` when starting with an absolute instant.
final class GregorianDate implements Comparable<GregorianDate> {
  GregorianDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError('Invalid Gregorian date: $year-$month-$day');
    }
  }

  /// Copies displayed fields. Does not convert the instant to another zone.
  factory GregorianDate.fromDateTime(DateTime date) =>
      GregorianDate(date.year, date.month, date.day);

  factory GregorianDate.fromEpochDay(int epochDay) =>
      GregorianDate.fromDateTime(
        DateTime.fromMillisecondsSinceEpoch(
          epochDay * Duration.millisecondsPerDay,
          isUtc: true,
        ),
      );

  factory GregorianDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Expected YYYY-MM-DD', value);
    return GregorianDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  final int year;
  final int month;
  final int day;
  int get epochDay =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// Dart weekday values: Monday = 1, Sunday = 7.
  int get weekday => DateTime.utc(year, month, day).weekday;
  GregorianDate advanced(int days) =>
      GregorianDate.fromEpochDay(epochDay + days);
  @override
  int compareTo(GregorianDate other) => epochDay.compareTo(other.epochDay);
  @override
  bool operator ==(Object other) =>
      other is GregorianDate && epochDay == other.epochDay;
  @override
  int get hashCode => epochDay.hashCode;
  @override
  String toString() => '${_pad(year, 4)}-${_pad(month, 2)}-${_pad(day, 2)}';
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');
