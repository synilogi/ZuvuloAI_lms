/// India Standard Time helpers (§21): a fixed +05:30 offset with no daylight saving, so no
/// timezone database is needed. Instants are always held as UTC `DateTime`s; these helpers move
/// between an instant and the wall-clock fields an Indian reader sees.
abstract final class Ist {
  static const offset = Duration(hours: 5, minutes: 30);

  /// The IST wall-clock reading of [instant], as a UTC-flagged `DateTime` whose fields
  /// (year … minute) are the IST fields. Use it only for display and picking.
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// The instant for an IST wall-clock reading.
  static DateTime instantFromWallClock(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
  ]) => DateTime.utc(year, month, day, hour, minute).subtract(offset);
}
