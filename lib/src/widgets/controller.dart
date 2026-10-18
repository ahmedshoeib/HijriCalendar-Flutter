import 'package:flutter/foundation.dart';

import '../../hijri_calendar_core.dart';

/// Owns calendar state and programmatic navigation. Dispose when no longer used.
final class HijriCalendarController extends ChangeNotifier {
  HijriCalendarController({
    HijriCalendarConfiguration? configuration,
    HijriSelectionMode selectionMode = HijriSelectionMode.single,
    HijriCalendarSelection? selection,
    HijriMonth? displayedMonth,
    DateTime Function()? clock,
  }) : _engine = HijriCalendarEngine(configuration: configuration),
       _selectionMode = selectionMode,
       _clock = clock ?? DateTime.now {
    _selection = _filtered(
      selection ?? HijriCalendarSelection.empty(selectionMode),
    );
    _displayedMonth = _engine.clampMonth(
      displayedMonth ?? _engine.todayMonth(now: _clock()),
    );
  }
  HijriCalendarEngine _engine;
  HijriSelectionMode _selectionMode;
  late HijriCalendarSelection _selection;
  late HijriMonth _displayedMonth;
  final DateTime Function() _clock;

  HijriCalendarEngine get engine => _engine;
  HijriCalendarConfiguration get configuration => _engine.configuration;
  HijriSelectionMode get selectionMode => _selectionMode;
  HijriCalendarSelection get selection => _selection;
  HijriMonth get displayedMonth => _displayedMonth;
  HijriMonthGrid get grid => _engine.monthGrid(_displayedMonth, now: _clock());
  bool get canGoBack => _engine.canDisplay(_displayedMonth.advanced(-1));
  bool get canGoForward => _engine.canDisplay(_displayedMonth.advanced(1));

  set selectionMode(HijriSelectionMode mode) {
    if (mode == _selectionMode) return;
    _selectionMode = mode;
    _selection = HijriCalendarSelection.empty(mode);
    notifyListeners();
  }

  set selection(HijriCalendarSelection value) {
    final next = _filtered(value);
    if (_selection == next) return;
    _selection = next;
    notifyListeners();
  }

  /// Validates before committing state. A calculation-system change clears selection.
  set configuration(HijriCalendarConfiguration value) {
    final next = HijriCalendarEngine(configuration: value);
    final systemChanged = value.calendarSystem != configuration.calendarSystem;
    _engine = next;
    _selection = systemChanged
        ? HijriCalendarSelection.empty(_selectionMode)
        : _filtered(_selection);
    _displayedMonth = _engine.clampMonth(
      systemChanged ? _engine.todayMonth(now: _clock()) : _displayedMonth,
    );
    notifyListeners();
  }

  HijriCalendarSelection _filtered(HijriCalendarSelection value) {
    if (value.mode != _selectionMode) {
      return HijriCalendarSelection.empty(_selectionMode);
    }
    final range = value.range;
    return switch (_selectionMode) {
      HijriSelectionMode.none => const HijriCalendarSelection.none(),
      HijriSelectionMode.single => HijriCalendarSelection.single(
        value.date != null && _engine.isSelectable(value.date!)
            ? value.date
            : null,
      ),
      HijriSelectionMode.multiple => HijriCalendarSelection.multiple(
        value.dates.where(_engine.isSelectable),
      ),
      HijriSelectionMode.range => HijriCalendarSelection.range(
        range != null &&
                _engine.isSelectable(range.lowerBound) &&
                (range.upperBound == null ||
                    _engine.isSelectable(range.upperBound!))
            ? range
            : null,
      ),
    };
  }

  /// Applies the same tap reducer used by the widget, including deselection.
  void select(HijriDate date) {
    if (!_engine.isSelectable(date)) return;
    selection = _selection.selecting(date, mode: _selectionMode);
  }

  void clearSelection() =>
      selection = HijriCalendarSelection.empty(_selectionMode);

  bool display(HijriMonth month) {
    if (!_engine.canDisplay(month) || month == _displayedMonth) return false;
    _displayedMonth = month;
    notifyListeners();
    return true;
  }

  bool nextMonth() => display(_displayedMonth.advanced(1));
  bool previousMonth() => display(_displayedMonth.advanced(-1));
  void displayToday() => display(_engine.todayMonth(now: _clock()));

  /// Refreshes today markers/decorations without changing selection.
  void refresh() => notifyListeners();
}
