import 'package:flutter/material.dart';

import '../../../core/format/ist.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';
import 'field_label.dart';

/// Picks a date and time as an **IST** wall-clock reading and reports the UTC instant (§21).
/// [format] renders the chosen instant for display (the date formatter from `core/format`).
class AppDateTimeField extends StatelessWidget {
  const AppDateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.format,
    super.key,
    this.firstDate,
    this.lastDate,
    this.includeTime = true,
    this.errorText,
    this.helperText,
  });

  final String label;

  /// The chosen instant (UTC), or null when nothing is chosen.
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final String Function(DateTime instant) format;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool includeTime;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return LabelledField(
      label: label,
      enabled: enabled,
      onLabelTap: enabled ? () => _pick(context) : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: enabled ? () => _pick(context) : null,
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              errorText: errorText,
              helperText: helperText,
              enabled: enabled,
              suffixIcon: AppIcon(AppIcons.date, size: 20, color: context.colors.muted),
            ),
            child: Text(
              value == null ? context.l10n.actionPickDate : format(value!),
              style: context.type.bodyM.copyWith(
                color: value == null ? context.colors.muted : context.colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final l10n = context.l10n;
    final now = Ist.wallClock(DateTime.now());
    final current = value == null ? now : Ist.wallClock(value!);
    final first = firstDate == null ? DateTime(now.year - 5) : Ist.wallClock(firstDate!);
    final last = lastDate == null ? DateTime(now.year + 5) : Ist.wallClock(lastDate!);
    final date = await showDatePicker(
      context: context,
      initialDate: _clamp(DateTime(current.year, current.month, current.day), first, last),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(last.year, last.month, last.day),
      helpText: l10n.actionPickDate,
    );
    if (date == null || !context.mounted) return;
    var time = TimeOfDay(hour: current.hour, minute: current.minute);
    if (includeTime) {
      final picked = await showTimePicker(
        context: context,
        initialTime: time,
        helpText: l10n.actionPickTime,
      );
      if (picked == null) return;
      time = picked;
    }
    onChanged?.call(
      Ist.instantFromWallClock(
        date.year,
        date.month,
        date.day,
        includeTime ? time.hour : 0,
        includeTime ? time.minute : 0,
      ),
    );
  }

  static DateTime _clamp(DateTime d, DateTime first, DateTime last) {
    final lo = DateTime(first.year, first.month, first.day);
    final hi = DateTime(last.year, last.month, last.day);
    if (d.isBefore(lo)) return lo;
    if (d.isAfter(hi)) return hi;
    return d;
  }
}
