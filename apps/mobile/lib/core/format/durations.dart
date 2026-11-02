import '../../l10n/l10n.dart';

/// Durations as the web writes them (`formatDuration`, `formatClock`).
abstract final class AppDurations {
  /// "45 min", "1h", "1h 05m".
  static String minutes(AppLocalizations l10n, num totalMinutes) {
    final min = totalMinutes.round();
    if (min < 60) return l10n.durationMinutes(min);
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0
        ? l10n.durationHours(h)
        : l10n.durationHoursMinutes(h, m.toString().padLeft(2, '0'));
  }

  /// "4:05" or "1:02:05" — a media clock.
  static String clock(num totalSeconds) {
    final s = totalSeconds.round() < 0 ? 0 : totalSeconds.round();
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
  }
}
