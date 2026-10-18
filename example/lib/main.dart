import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hijri_calendar_flutter/hijri_calendar_flutter.dart';

void main() => runApp(const CalendarShowcase());

class CalendarShowcase extends StatefulWidget {
  const CalendarShowcase({super.key});
  @override
  State<CalendarShowcase> createState() => _CalendarShowcaseState();
}

class _CalendarShowcaseState extends State<CalendarShowcase> {
  bool _dark = false;
  bool _arabic = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hijri Calendar',
    debugShowCheckedModeBanner: false,
    locale: Locale(_arabic ? 'ar' : 'en'),
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: _ShowcaseHome(
      arabic: _arabic,
      dark: _dark,
      onLanguageChanged: () => setState(() => _arabic = !_arabic),
      onThemeChanged: () => setState(() => _dark = !_dark),
    ),
  );

  ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF13776C),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF3F5F1)
          : const Color(0xFF111917),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    );
  }
}

class _ShowcaseHome extends StatefulWidget {
  const _ShowcaseHome({
    required this.arabic,
    required this.dark,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });
  final bool arabic;
  final bool dark;
  final VoidCallback onLanguageChanged;
  final VoidCallback onThemeChanged;
  @override
  State<_ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<_ShowcaseHome> {
  late final HijriCalendarController _controller;
  final _officialStart = TextEditingController();
  bool _events = true;
  bool _disableFridays = false;
  bool _customLabels = false;
  bool _bounded = false;
  String? _error;

  String text(String en, String ar) => widget.arabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _controller = HijriCalendarController(
      configuration: HijriCalendarConfiguration(
        localeIdentifier: widget.arabic ? 'ar' : 'en',
        timeZoneIdentifier: 'Asia/Dubai',
        firstWeekday: 7,
      ),
    );
  }

  @override
  void didUpdateWidget(_ShowcaseHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arabic != widget.arabic) {
      _controller.configuration = _controller.configuration.copyWith(
        localeIdentifier: widget.arabic ? 'ar' : 'en',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _officialStart.dispose();
    super.dispose();
  }

  void _configure(HijriCalendarConfiguration configuration) {
    try {
      _controller.configuration = configuration;
      setState(() => _error = null);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: Text(text('Hijri Calendar', 'التقويم الهجري')),
      actions: [
        TextButton.icon(
          key: const ValueKey('language-toggle'),
          onPressed: widget.onLanguageChanged,
          icon: const Icon(Icons.translate),
          label: Text(widget.arabic ? 'English' : 'العربية'),
        ),
        IconButton(
          key: const ValueKey('theme-toggle'),
          tooltip: text('Change theme', 'تغيير المظهر'),
          onPressed: widget.onThemeChanged,
          icon: Icon(
            widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 500 ? 16 : 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text('Make time your own.', 'تقويم يناسب احتياجاتك.'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text(
                        'Explore Hijri dates, events, selections, and local month starts.',
                        'استكشف التواريخ والأحداث والاختيارات وبدايات الأشهر المحلية.',
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _calendarPanel()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _settings()),
                        ],
                      )
                    else ...[
                      _calendarPanel(),
                      const SizedBox(height: 20),
                      _settings(),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      text(
                        'All calendar calculations work offline. Official starts are supplied by your app.',
                        'تعمل الحسابات دون اتصال. يزوّد تطبيقك التقويم ببدايات الأشهر الرسمية.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _card(Widget child) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );

  Widget _calendarPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _systemName(_controller.configuration.calendarSystem),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    _controller.configuration.localeIdentifier.toUpperCase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            HijriCalendar(
              controller: _controller,
              minimumDayLabelDigits: 2,
              style: const HijriCalendarStyle(
                padding: EdgeInsets.zero,
                cellHeight: 54,
              ),
              dayDecoration: (date) {
                final gregorian = _controller.engine.isSupported(date)
                    ? _controller.engine.toGregorian(date)
                    : null;
                return HijriCalendarDayDecoration(
                  hasEvent: _events && const [1, 10, 15, 23].contains(date.day),
                  eventColor: _events && date.day == 15 ? Colors.orange : null,
                  isEnabled:
                      !(_disableFridays &&
                          gregorian?.weekday == DateTime.friday),
                  label: _customLabels && date.day == 1
                      ? text('Start', 'بداية')
                      : null,
                  tooltip: _events && date.day == 15
                      ? text('Your event', 'حدثك')
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _legend(
                  Icons.radio_button_unchecked,
                  text('Today', 'اليوم'),
                  Theme.of(context).colorScheme.primary,
                ),
                _legend(
                  Icons.circle,
                  text('Selected', 'محدد'),
                  Theme.of(context).colorScheme.primary,
                ),
                _legend(
                  Icons.fiber_manual_record,
                  text('Event', 'حدث'),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    text('Your selection', 'اختيارك'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _controller.clearSelection,
                  child: Text(text('Clear', 'مسح')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectionSummary(),
              key: const ValueKey('selection-summary'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in HijriSelectionMode.values)
                  ChoiceChip(
                    label: Text(_modeName(mode)),
                    selected: _controller.selectionMode == mode,
                    onSelected: (_) => _controller.selectionMode = mode,
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _card(_authorityControls()),
    ],
  );

  Widget _legend(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(label),
    ],
  );

  String _selectionSummary() {
    final labels = _controller.engine.labels;
    final selection = _controller.selection;
    return switch (selection.mode) {
      HijriSelectionMode.none => text(
        'Read-only calendar. Browse dates and events.',
        'تقويم للعرض. استعرض التواريخ والأحداث.',
      ),
      HijriSelectionMode.single =>
        selection.date == null
            ? text('Choose a day to get started.', 'اختر يومًا للبدء.')
            : '${labels.dateLabel(selection.date!)}\n${_controller.engine.toGregorian(selection.date!)}',
      HijriSelectionMode.multiple =>
        selection.dates.isEmpty
            ? text('Choose any number of days.', 'اختر أي عدد من الأيام.')
            : (selection.dates.toList()..sort())
                  .map(labels.dateLabel)
                  .join(' · '),
      HijriSelectionMode.range =>
        selection.range == null
            ? text(
                'Choose the first day of your range.',
                'اختر أول يوم من الفترة.',
              )
            : '${labels.dateLabel(selection.range!.lowerBound)} → ${selection.range!.upperBound == null ? text('Choose an end day', 'اختر يوم النهاية') : labels.dateLabel(selection.range!.upperBound!)}',
    };
  }

  Widget _settings() {
    final configuration = _controller.configuration;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text('Calendar settings', 'إعدادات التقويم'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<HijriCalendarSystem>(
            initialValue: configuration.calendarSystem,
            decoration: InputDecoration(
              labelText: text('Calculation system', 'نظام الحساب'),
            ),
            items: [
              for (final system in HijriCalendarSystem.values)
                DropdownMenuItem(
                  value: system,
                  child: Text(_systemName(system)),
                ),
            ],
            onChanged: (system) {
              if (system == null) return;
              _bounded = false;
              _configure(
                configuration.copyWith(
                  calendarSystem: system,
                  clearBounds: true,
                  monthStartOverrides: [],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: configuration.timeZoneIdentifier,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: text('Time zone', 'المنطقة الزمنية'),
            ),
            items: [
              for (final zone in [
                'local',
                'UTC',
                'Asia/Dubai',
                'Asia/Riyadh',
                'America/New_York',
              ])
                DropdownMenuItem(value: zone, child: Text(zone)),
            ],
            onChanged: (zone) {
              if (zone != null) {
                _configure(configuration.copyWith(timeZoneIdentifier: zone));
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: configuration.firstWeekday,
            decoration: InputDecoration(
              labelText: text('First weekday', 'أول أيام الأسبوع'),
            ),
            items: [
              for (var day = 1; day <= 7; day++)
                DropdownMenuItem(
                  value: day,
                  child: Text(
                    (widget.arabic
                        ? [
                            'الأحد',
                            'الاثنين',
                            'الثلاثاء',
                            'الأربعاء',
                            'الخميس',
                            'الجمعة',
                            'السبت',
                          ]
                        : [
                            'Sunday',
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                          ])[day - 1],
                  ),
                ),
            ],
            onChanged: (day) {
              if (day != null) {
                _configure(configuration.copyWith(firstWeekday: day));
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HijriLayoutDirection>(
            initialValue: configuration.layoutDirection,
            decoration: InputDecoration(
              labelText: text('Layout direction', 'اتجاه العرض'),
            ),
            items: [
              DropdownMenuItem(
                value: HijriLayoutDirection.automatic,
                child: Text(text('Automatic', 'تلقائي')),
              ),
              DropdownMenuItem(
                value: HijriLayoutDirection.leftToRight,
                child: Text(text('Left to right', 'من اليسار إلى اليمين')),
              ),
              DropdownMenuItem(
                value: HijriLayoutDirection.rightToLeft,
                child: Text(text('Right to left', 'من اليمين إلى اليسار')),
              ),
            ],
            onChanged: (direction) {
              if (direction != null) {
                _configure(configuration.copyWith(layoutDirection: direction));
              }
            },
          ),
          const SizedBox(height: 20),
          Text(
            '${text('Day adjustment', 'تعديل الأيام')}: ${configuration.dayAdjustment > 0 ? '+' : ''}${configuration.dayAdjustment}',
          ),
          Slider(
            value: configuration.dayAdjustment.toDouble(),
            min: -2,
            max: 2,
            divisions: 4,
            label: configuration.dayAdjustment.toString(),
            onChanged: configuration.monthStartOverrides.isNotEmpty
                ? null
                : (value) => _configure(
                    configuration.copyWith(dayAdjustment: value.toInt()),
                  ),
          ),
          if (configuration.monthStartOverrides.isNotEmpty)
            Text(
              text(
                'Official month starts take precedence.',
                'تُعتمد بدايات الأشهر الرسمية أولاً.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const Divider(height: 28),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(text('Adjacent month dates', 'تواريخ الأشهر المجاورة')),
            value: configuration.showsAdjacentMonthDates,
            onChanged: (value) => _configure(
              configuration.copyWith(showsAdjacentMonthDates: value),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(text('Event markers', 'علامات الأحداث')),
            value: _events,
            onChanged: (value) => setState(() => _events = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(text('Disable Fridays', 'تعطيل أيام الجمعة')),
            value: _disableFridays,
            onChanged: (value) => setState(() => _disableFridays = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(text('Custom day labels', 'تسميات أيام مخصصة')),
            value: _customLabels,
            onChanged: (value) => setState(() => _customLabels = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              text(
                'Limit to days 5–25 this month',
                'تحديد الأيام من ٥ إلى ٢٥ لهذا الشهر',
              ),
            ),
            value: _bounded,
            onChanged: (value) {
              final month = _controller.displayedMonth;
              _bounded = value;
              _configure(
                configuration.copyWith(
                  clearBounds: !value,
                  minimumDate: value
                      ? HijriDate(month.year, month.month, 5)
                      : null,
                  maximumDate: value
                      ? HijriDate(month.year, month.month, 25)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _authorityControls() {
    final configuration = _controller.configuration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text('Official month start', 'بداية الشهر الرسمية'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          text(
            'Enter the Gregorian day published by your chosen authority for the displayed month.',
            'أدخل اليوم الميلادي الذي أعلنته الجهة المعتمدة لبداية الشهر المعروض.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _officialStart,
          keyboardType: TextInputType.datetime,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: text(
              'Gregorian start · YYYY-MM-DD',
              'بداية الشهر الميلادية · YYYY-MM-DD',
            ),
            hintText: _controller.engine
                .toGregorian(_controller.displayedMonth.firstDay)
                .toString(),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                try {
                  final start = GregorianDate.parse(_officialStart.text.trim());
                  _configure(
                    configuration.withMonthStartOverride(
                      _controller.displayedMonth,
                      start,
                    ),
                  );
                } on FormatException {
                  setState(
                    () =>
                        _error = text('Use YYYY-MM-DD.', 'استخدم YYYY-MM-DD.'),
                  );
                } on ArgumentError {
                  setState(
                    () => _error = text(
                      'Enter a valid Gregorian day.',
                      'أدخل يومًا ميلاديًا صحيحًا.',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: Text(text('Apply start', 'اعتماد البداية')),
            ),
            OutlinedButton(
              onPressed: configuration.monthStartOverrides.isEmpty
                  ? null
                  : () => _configure(
                      configuration.copyWith(monthStartOverrides: []),
                    ),
              child: Text(text('Clear overrides', 'مسح التعديلات')),
            ),
          ],
        ),
        if (configuration.monthStartOverrides.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final override in configuration.monthStartOverrides)
            Text(
              '${_controller.engine.labels.monthTitle(override.month)} · ${override.gregorianStartDate}',
            ),
        ],
      ],
    );
  }

  String _systemName(HijriCalendarSystem system) => switch (system) {
    HijriCalendarSystem.ummAlQura => text('Umm al-Qura', 'أم القرى'),
    HijriCalendarSystem.islamic => text('Islamic', 'الإسلامي'),
    HijriCalendarSystem.civil => text('Islamic Civil', 'الإسلامي المدني'),
    HijriCalendarSystem.tabular => text('Islamic Tabular', 'الإسلامي الجدولي'),
  };
  String _modeName(HijriSelectionMode mode) => switch (mode) {
    HijriSelectionMode.none => text('Read only', 'عرض فقط'),
    HijriSelectionMode.single => text('Single', 'مفرد'),
    HijriSelectionMode.multiple => text('Multiple', 'متعدد'),
    HijriSelectionMode.range => text('Range', 'فترة'),
  };
}
