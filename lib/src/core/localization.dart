import 'package:intl/intl.dart';

import 'date.dart';

/// Per-instance English/Arabic strings. Custom UI builders may supply other names.
final class HijriCalendarLabels {
  HijriCalendarLabels(this.localeIdentifier) {
    final locale = localeIdentifier.replaceAll('-', '_');
    _numbers = NumberFormat(
      '0',
      NumberFormat.localeExists(locale)
          ? locale
          : NumberFormat.localeExists(language)
          ? language
          : 'en',
    );
  }
  final String localeIdentifier;
  late final NumberFormat _numbers;
  String get language =>
      localeIdentifier.toLowerCase().split(RegExp('[_-]')).first;
  bool get isArabic => language == 'ar';
  static const _englishMonths = [
    'Muharram',
    'Safar',
    'Rabiʻ I',
    'Rabiʻ II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Shaʻban',
    'Ramadan',
    'Shawwal',
    'Dhuʻl-Qiʻdah',
    'Dhuʻl-Hijjah',
  ];
  static const _arabicMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  static const _englishWeekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static const _arabicWeekdays = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];
  static const _englishSymbols = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  static const _arabicSymbols = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];

  String number(int value, {int minimumDigits = 1}) {
    _numbers.minimumIntegerDigits = minimumDigits.clamp(1, 6);
    final formatted = _numbers.format(value);
    final zero = isArabic
        ? 0x0660
        : (language == 'fa' || language == 'ur')
        ? 0x06F0
        : null;
    if (zero == null) return formatted;
    return formatted.replaceAllMapped(
      RegExp('[0-9]'),
      (match) => String.fromCharCode(zero + int.parse(match[0]!)),
    );
  }

  String monthName(int month) =>
      (isArabic ? _arabicMonths : _englishMonths)[month - 1];
  String monthTitle(HijriMonth month) =>
      '${monthName(month.month)} ${number(month.year)}';
  String dayLabel(HijriDate date, {int minimumDigits = 1}) =>
      number(date.day, minimumDigits: minimumDigits);
  String dateLabel(HijriDate date) =>
      '${dayLabel(date)} ${monthTitle(date.hijriMonth)}';
  String fullDateLabel(HijriDate date, GregorianDate gregorian) =>
      '${(isArabic ? _arabicWeekdays : _englishWeekdays)[gregorian.weekday % 7]}, ${dateLabel(date)}';
  List<String> weekdaySymbols({int firstWeekday = 1}) {
    RangeError.checkValueInInterval(firstWeekday, 1, 7, 'firstWeekday');
    final symbols = isArabic ? _arabicSymbols : _englishSymbols;
    return List.generate(7, (index) => symbols[(index + firstWeekday - 1) % 7]);
  }

  String get previousMonth => isArabic ? 'الشهر السابق' : 'Previous month';
  String get nextMonth => isArabic ? 'الشهر التالي' : 'Next month';
  String get today => isArabic ? 'اليوم' : 'Today';
}
