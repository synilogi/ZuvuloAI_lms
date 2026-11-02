import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import 'ist.dart';

/// Date display on the academy clock — IST, as the web's `lib/format.ts` does (§21, C12). Every
/// input is an instant (UTC `DateTime` from the server); every output reads in IST.
abstract final class DatesIst {
  static const _locale = 'en';

  static String _fmt(String pattern, DateTime instant) =>
      DateFormat(pattern, _locale).format(Ist.wallClock(instant));

  /// "Thu, 17 Sep"
  static String day(DateTime instant) => _fmt('EEE, d MMM', instant);

  /// "17 Sep 2026"
  static String date(DateTime instant) => _fmt('d MMM yyyy', instant);

  /// "15 Sep"
  static String shortDate(DateTime instant) => _fmt('d MMM', instant);

  /// The first letter of the weekday, for a week strip's column heads.
  static String weekdayInitial(DateTime instant) => _fmt('EEEEE', instant);

  /// "Tuesday, 15 September"
  static String longDay(DateTime instant) => _fmt('EEEE, d MMMM', instant);

  /// "7:00 PM"
  static String time(DateTime instant) => _fmt('h:mm a', instant).toUpperCase();

  /// "7:00 PM – 8:00 PM IST"
  static String timeRange(AppLocalizations l10n, DateTime start, Duration length) =>
      l10n.timeRangeWithZone(time(start), time(start.add(length)));

  /// "17 Sep 2026, 7:00 PM" plus " IST" when the device is in another zone.
  static String dateTime(AppLocalizations l10n, DateTime instant, {DateTime? deviceNow}) {
    final text = '${date(instant)}, ${time(instant)}';
    return needsZoneLabel(deviceNow: deviceNow) ? l10n.timeWithZone(text) : text;
  }

  /// { day: "17", month: "Sep", weekday: "Thu" } for date blocks.
  static ({String day, String month, String weekday}) parts(DateTime instant) =>
      (day: _fmt('d', instant), month: _fmt('MMM', instant), weekday: _fmt('EEE', instant));

  /// Whether times need an "IST" label: the device's zone is not IST.
  static bool needsZoneLabel({DateTime? deviceNow}) =>
      (deviceNow ?? DateTime.now()).timeZoneOffset != Ist.offset;

  /// The IST calendar day of [instant], as a date-only UTC `DateTime` — the key for agenda grouping.
  static DateTime dayKey(DateTime instant) {
    final wall = Ist.wallClock(instant);
    return DateTime.utc(wall.year, wall.month, wall.day);
  }

  /// The instant IST midnight begins the day containing [instant].
  static DateTime startOfDay(DateTime instant) {
    final wall = Ist.wallClock(instant);
    return Ist.instantFromWallClock(wall.year, wall.month, wall.day);
  }

  static bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

  /// "2026-09-23" — the IST date form calendar `from`/`to` queries use. A wire format, so it is
  /// built from the IST wall-clock fields rather than through `DateFormat`: a query must not depend
  /// on locale data being initialised, which a service reached outside a `MaterialApp` cannot assume.
  static String queryDate(DateTime instant) {
    final wall = Ist.wallClock(instant);
    final month = wall.month.toString().padLeft(2, '0');
    final day = wall.day.toString().padLeft(2, '0');
    return '${wall.year.toString().padLeft(4, '0')}-$month-$day';
  }

  /// "Good morning" before 12:00 IST, "Good afternoon" before 17:00, else "Good evening".
  static String greeting(AppLocalizations l10n, DateTime now) {
    final hour = Ist.wallClock(now).hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  /// "now", "in 12 minutes", "3 hours ago", "tomorrow", "in 2 days" — the web's thresholds:
  /// under a minute, minutes under an hour, hours under a day, then days.
  static String relative(AppLocalizations l10n, DateTime instant, DateTime now) {
    final diff = instant.difference(now);
    final abs = diff.abs();
    final future = !diff.isNegative;
    int rounded(Duration unit) => (abs.inMicroseconds / unit.inMicroseconds).round();
    if (abs < const Duration(minutes: 1)) return l10n.relativeNow;
    if (abs < const Duration(hours: 1)) {
      final n = rounded(const Duration(minutes: 1));
      return future ? l10n.relativeMinutesFuture(n) : l10n.relativeMinutesPast(n);
    }
    if (abs < const Duration(days: 1)) {
      final n = rounded(const Duration(hours: 1));
      return future ? l10n.relativeHoursFuture(n) : l10n.relativeHoursPast(n);
    }
    final n = rounded(const Duration(days: 1));
    return future ? l10n.relativeDaysFuture(n) : l10n.relativeDaysPast(n);
  }
}
