import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../../hijri_calendar_core.dart';
import 'controller.dart';
import 'style.dart';

typedef HijriDayDecorationBuilder =
    HijriCalendarDayDecoration? Function(HijriDate date);
typedef HijriDayWidgetBuilder =
    Widget? Function(BuildContext context, HijriCalendarDayDetails details);

/// An inline six-week Hijri calendar for mobile, desktop, and web.
///
/// Supply a [controller] for externally managed state and programmatic navigation.
/// Otherwise the widget owns its state; initial values apply only on creation.
class HijriCalendar extends StatefulWidget {
  const HijriCalendar({
    super.key,
    this.controller,
    this.configuration,
    this.initialDisplayedMonth,
    this.initialSelection,
    this.selectionMode = HijriSelectionMode.single,
    this.onSelectionChanged,
    this.onDisplayedMonthChanged,
    this.onDateTap,
    this.style = const HijriCalendarStyle(),
    this.dayDecoration,
    this.dayBuilder,
    this.dayLabelBuilder,
    this.monthTitleBuilder,
    this.weekdaySymbols,
    this.minimumDayLabelDigits = 1,
    this.showsNavigationButtons = true,
    this.showsTodayButton = true,
    this.enableSwipeNavigation = true,
  }) : assert(
         controller == null ||
             (configuration == null &&
                 initialDisplayedMonth == null &&
                 initialSelection == null),
         'Configure an external controller directly.',
       ),
       assert(weekdaySymbols == null || weekdaySymbols.length == 7);

  final HijriCalendarController? controller;
  final HijriCalendarConfiguration? configuration;
  final HijriMonth? initialDisplayedMonth;
  final HijriCalendarSelection? initialSelection;

  /// Used only when the widget owns its controller.
  final HijriSelectionMode selectionMode;
  final ValueChanged<HijriCalendarSelection>? onSelectionChanged;
  final ValueChanged<HijriMonth>? onDisplayedMonthChanged;
  final ValueChanged<HijriDate>? onDateTap;
  final HijriCalendarStyle style;
  final HijriDayDecorationBuilder? dayDecoration;
  final HijriDayWidgetBuilder? dayBuilder;
  final String Function(HijriDate date)? dayLabelBuilder;
  final String Function(HijriMonth month)? monthTitleBuilder;

  /// Seven symbols starting at the configured first weekday, in logical order.
  final List<String>? weekdaySymbols;
  final int minimumDayLabelDigits;
  final bool showsNavigationButtons;
  final bool showsTodayButton;
  final bool enableSwipeNavigation;

  @override
  State<HijriCalendar> createState() => _HijriCalendarState();
}

class _HijriCalendarState extends State<HijriCalendar> {
  late HijriCalendarController _controller;
  late HijriCalendarSelection _lastSelection;
  late HijriMonth _lastMonth;
  final _focusNodes = List.generate(42, (_) => FocusNode());
  HijriDate? _focusedDate;
  HijriDate? _pendingFocus;
  bool _synchronizing = false;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _controller =
        widget.controller ??
        HijriCalendarController(
          configuration: widget.configuration,
          selectionMode: widget.selectionMode,
          selection: widget.initialSelection,
          displayedMonth: widget.initialDisplayedMonth,
        );
    _lastSelection = _controller.selection;
    _lastMonth = _controller.displayedMonth;
    _controller.addListener(_changed);
  }

  void _changed() {
    final selectionChanged = _lastSelection != _controller.selection;
    final monthChanged = _lastMonth != _controller.displayedMonth;
    _lastSelection = _controller.selection;
    _lastMonth = _controller.displayedMonth;
    if (_synchronizing) return;
    setState(() {});
    if (selectionChanged) widget.onSelectionChanged?.call(_lastSelection);
    if (monthChanged) widget.onDisplayedMonthChanged?.call(_lastMonth);
  }

  void _inheritLocale() {
    if (widget.controller != null || widget.configuration != null) return;
    final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en';
    if (_controller.configuration.localeIdentifier != locale) {
      _controller.configuration = _controller.configuration.copyWith(
        localeIdentifier: locale,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronizing = true;
    _inheritLocale();
    _synchronizing = false;
  }

  @override
  void didUpdateWidget(HijriCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizing = true;
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_changed);
      if (oldWidget.controller == null) _controller.dispose();
      _attach();
    } else if (widget.controller == null) {
      if (widget.configuration != oldWidget.configuration) {
        _controller.configuration =
            widget.configuration ?? HijriCalendarConfiguration();
      }
      _controller.selectionMode = widget.selectionMode;
    }
    _inheritLocale();
    _synchronizing = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    if (widget.controller == null) _controller.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  HijriCalendarDayDecoration? _decoration(HijriDate date) =>
      _controller.engine.isSupported(date)
      ? widget.dayDecoration?.call(date)
      : null;

  bool _enabled(HijriCalendarDay day, HijriCalendarDayDecoration? decoration) =>
      day.isWithinBounds && (decoration?.isEnabled ?? true);

  void _tap(HijriCalendarDay day) {
    if (!_enabled(day, _decoration(day.date))) return;
    _focusedDate = day.date;
    final index = _controller.grid.days.indexWhere(
      (value) => value.date == day.date,
    );
    if (index >= 0) _focusNodes[index].requestFocus();
    _controller.select(day.date);
    widget.onDateTap?.call(day.date);
  }

  void _navigate(int delta) {
    _focusedDate = null;
    _controller.display(_controller.displayedMonth.advanced(delta));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final current = _focusedDate ?? _controller.displayedMonth.firstDay;
    final engine = _controller.engine;
    final rtl = _controller.configuration.isRightToLeft;
    final int delta;
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final month = current.hijriMonth.advanced(
        key == LogicalKeyboardKey.pageUp ? -1 : 1,
      );
      if (engine.canDisplay(month)) {
        _focusDate(
          HijriDate(
            month.year,
            month.month,
            math.min(current.day, engine.daysInMonth(month)),
          ),
        );
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      delta = rtl ? 1 : -1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      delta = rtl ? -1 : 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      delta = -7;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      delta = 7;
    } else if (key == LogicalKeyboardKey.home ||
        key == LogicalKeyboardKey.end) {
      final civil = engine.toGregorian(current)!;
      final offset =
          (civil.weekday % 7 + 1 - _controller.configuration.firstWeekday + 7) %
          7;
      delta = key == LogicalKeyboardKey.home ? -offset : 6 - offset;
    } else {
      return KeyEventResult.ignored;
    }
    try {
      _focusDate(
        engine.fromGregorian(engine.toGregorian(current)!.advanced(delta)),
        direction: delta < 0 ? -1 : 1,
      );
    } on RangeError {
      // Navigation stops at the supported range.
    }
    return KeyEventResult.handled;
  }

  void _focusDate(HijriDate target, {int direction = 1}) {
    final engine = _controller.engine;
    var date = target;
    for (var attempt = 0; attempt < 42; attempt++) {
      if (!engine.isSelectable(date)) return;
      if (_decoration(date)?.isEnabled ?? true) break;
      if (attempt == 41) return;
      try {
        date = engine.fromGregorian(
          engine.toGregorian(date)!.advanced(direction),
        );
      } on RangeError {
        return;
      }
    }
    _pendingFocus = date;
    _focusedDate = date;
    if (!_controller.display(date.hijriMonth)) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final configuration = _controller.configuration;
    final labels = _controller.engine.labels;
    final style = widget.style;
    final grid = _controller.grid;
    final weekdays =
        widget.weekdaySymbols ??
        labels.weekdaySymbols(firstWeekday: configuration.firstWeekday);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final height = math.max(style.cellHeight, 30 + 18 * scale);
    if (_pendingFocus != null) {
      final index = grid.days.indexWhere((day) => day.date == _pendingFocus);
      _pendingFocus = null;
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusNodes[index].canRequestFocus) {
            _focusNodes[index].requestFocus();
          }
        });
      }
    }
    return Directionality(
      textDirection: configuration.isRightToLeft
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Material(
        color: style.backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: style.padding,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.enableSwipeNavigation
                ? (_) => _dragDistance = 0
                : null,
            onHorizontalDragUpdate: widget.enableSwipeNavigation
                ? (details) => _dragDistance += details.delta.dx
                : null,
            onHorizontalDragEnd: widget.enableSwipeNavigation
                ? (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (_dragDistance.abs() < 40 && velocity.abs() < 200) {
                      return;
                    }
                    final movingLeft = _dragDistance.abs() >= 40
                        ? _dragDistance < 0
                        : velocity < 0;
                    _navigate(
                      movingLeft != configuration.isRightToLeft ? 1 : -1,
                    );
                  }
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (widget.showsNavigationButtons)
                      IconButton(
                        key: const ValueKey('hijri-previous'),
                        tooltip: labels.previousMonth,
                        onPressed: _controller.canGoBack
                            ? () => _navigate(-1)
                            : null,
                        icon: Icon(
                          configuration.isRightToLeft
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                        ),
                      ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          widget.monthTitleBuilder?.call(grid.month) ??
                              labels.monthTitle(grid.month),
                          key: const ValueKey('hijri-month-title'),
                          textAlign: TextAlign.center,
                          style:
                              style.headerTextStyle ??
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    if (widget.showsTodayButton)
                      IconButton(
                        key: const ValueKey('hijri-today'),
                        tooltip: labels.today,
                        onPressed: _controller.displayToday,
                        icon: const Icon(Icons.today_outlined),
                      ),
                    if (widget.showsNavigationButtons)
                      IconButton(
                        key: const ValueKey('hijri-next'),
                        tooltip: labels.nextMonth,
                        onPressed: _controller.canGoForward
                            ? () => _navigate(1)
                            : null,
                        icon: Icon(
                          configuration.isRightToLeft
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (final symbol in weekdays)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              symbol,
                              textAlign: TextAlign.center,
                              style:
                                  style.weekdayTextStyle ??
                                  theme.textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Focus(
                  onKeyEvent: _handleKey,
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: Column(
                      children: [
                        for (var row = 0; row < 6; row++)
                          Row(
                            children: [
                              for (var column = 0; column < 7; column++)
                                Expanded(
                                  child: SizedBox(
                                    height: height,
                                    child: _day(
                                      context,
                                      grid.days[row * 7 + column],
                                      row * 7 + column,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _day(BuildContext context, HijriCalendarDay day, int index) {
    final style = widget.style;
    if (day.monthPosition != HijriMonthPosition.current &&
        !_controller.configuration.showsAdjacentMonthDates) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decoration = _decoration(day.date);
    final enabled = _enabled(day, decoration);
    final selection = _controller.selection;
    final selected = selection.contains(day.date);
    final endpoint =
        selection.mode != HijriSelectionMode.range ||
        selection.range?.lowerBound == day.date ||
        selection.range?.upperBound == day.date;
    final filled = selected && endpoint;
    final labels = _controller.engine.labels;
    final label =
        decoration?.label ??
        widget.dayLabelBuilder?.call(day.date) ??
        labels.dayLabel(day.date, minimumDigits: widget.minimumDayLabelDigits);
    final foreground = !enabled
        ? colors.onSurface.withValues(alpha: 0.35)
        : filled
        ? style.selectedTextColor ?? colors.onPrimary
        : decoration?.textColor ??
              (day.monthPosition == HijriMonthPosition.current
                  ? style.textColor ?? colors.onSurface
                  : style.adjacentTextColor ??
                        colors.onSurfaceVariant.withValues(alpha: 0.65));
    final background = filled
        ? style.selectionColor ?? colors.primary
        : selected
        ? style.rangeColor ?? colors.primaryContainer
        : decoration?.backgroundColor ?? Colors.transparent;
    final hasEvent =
        decoration?.hasEvent == true || decoration?.eventColor != null;
    final custom = widget.dayBuilder?.call(
      context,
      HijriCalendarDayDetails(
        day: day,
        isSelected: selected,
        isRangeEndpoint: selected && endpoint,
        isEnabled: enabled,
        label: label,
        decoration: decoration,
      ),
    );
    final content =
        custom ??
        Padding(
          padding: EdgeInsets.all(style.cellSpacing),
          child: Ink(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(style.dayCornerRadius),
              border: day.isToday
                  ? Border.all(
                      color: filled
                          ? foreground
                          : style.todayColor ?? colors.primary,
                      width: 1.5,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: hasEvent ? 6 : 0),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: (style.dayTextStyle ?? theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: foreground,
                          fontWeight: filled || day.isToday
                              ? FontWeight.w700
                              : null,
                        ),
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    bottom: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? foreground
                            : decoration?.eventColor ??
                                  style.eventColor ??
                                  colors.tertiary,
                      ),
                      child: const SizedBox(width: 5, height: 5),
                    ),
                  ),
              ],
            ),
          ),
        );
    Widget tile = Semantics(
      key: ValueKey(
        'hijri-day-${day.date.year}-${day.date.month}-${day.date.day}',
      ),
      button: true,
      focusable: enabled,
      focused: _focusNodes[index].hasFocus,
      enabled: enabled,
      selected: selected,
      sortKey: OrdinalSortKey(index.toDouble()),
      label:
          decoration?.accessibilityLabel ??
          labels.fullDateLabel(day.date, day.gregorianDate),
      value: day.isToday ? labels.today : null,
      onTap: enabled ? () => _tap(day) : null,
      child: ExcludeSemantics(
        child: InkWell(
          focusNode: _focusNodes[index],
          canRequestFocus: enabled,
          borderRadius: BorderRadius.circular(style.dayCornerRadius),
          onTap: enabled ? () => _tap(day) : null,
          onFocusChange: (focused) {
            if (mounted) {
              setState(() {
                if (focused) _focusedDate = day.date;
              });
            }
          },
          child: content,
        ),
      ),
    );
    if (decoration?.tooltip != null) {
      tile = Tooltip(message: decoration!.tooltip!, child: tile);
    }
    return tile;
  }
}
