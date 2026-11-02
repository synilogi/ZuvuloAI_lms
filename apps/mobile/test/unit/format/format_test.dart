import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/format/dates_ist.dart';
import 'package:syniastrolms_mobile/core/format/durations.dart';
import 'package:syniastrolms_mobile/core/format/ist.dart';
import 'package:syniastrolms_mobile/core/format/money.dart';
import 'package:syniastrolms_mobile/l10n/generated/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('Money', () {
    test('formats minor units with Indian grouping', () {
      expect(Money.format(399900, 'INR'), '₹3,999.00');
      expect(Money.format(10000000, 'INR'), '₹1,00,000.00');
      expect(Money.format(5, 'INR'), '₹0.05');
      expect(Money.format(0, 'INR'), '₹0.00');
      expect(Money.format(-150050, 'INR'), '-₹1,500.50');
    });

    test('uses the currency\'s own minor-unit digits', () {
      expect(Money.digits('INR'), 2);
      expect(Money.digits('JPY'), 0);
      expect(Money.digits('KWD'), 3);
      expect(Money.format(1500, 'JPY'), contains('1,500'));
      expect(Money.format(1500, 'JPY'), isNot(contains('.')));
      expect(Money.format(12345, 'KWD'), endsWith('12.345'));
    });

    test('can drop a zero fraction for whole-rupee prices, as the web does', () {
      expect(Money.format(399900, 'INR', dropZeroFraction: true), '₹3,999');
      expect(Money.format(399950, 'INR', dropZeroFraction: true), '₹3,999.50');
    });

    test('an unknown or malformed currency is written as a code', () {
      expect(Money.format(1234, 'ZZZ'), 'ZZZ 12.34');
      expect(Money.format(1234, 'rupees'), 'RUPEES 12.34');
    });

    test('is exact for large amounts (integer arithmetic, no double)', () {
      // 2^53 - 1 paise; a double division would lose the last digits.
      expect(Money.format(9007199254740991, 'INR'), '₹9,00,71,99,25,47,409.91');
    });

    test('formatCount groups the Indian way', () {
      expect(formatCount(1234567), '12,34,567');
    });
  });

  group('IST dates', () {
    final boundary = DateTime.utc(2026, 9, 22, 18, 30);

    test('18:30 UTC is 23 Sep 00:00 IST', () {
      expect(DatesIst.date(boundary), '23 Sep 2026');
      expect(DatesIst.time(boundary), '12:00 AM');
      expect(DatesIst.dayKey(boundary), DateTime.utc(2026, 9, 23));
      expect(
        DatesIst.dayKey(boundary.subtract(const Duration(minutes: 1))),
        DateTime.utc(2026, 9, 22),
      );
      expect(DatesIst.queryDate(boundary), '2026-09-23');
    });

    test('startOfDay and sameDay follow IST midnight', () {
      final lateEvening = DateTime.utc(2026, 9, 23, 17, 0); // 22:30 IST on the 23rd
      expect(DatesIst.startOfDay(lateEvening), boundary);
      expect(DatesIst.sameDay(boundary, lateEvening), isTrue);
      expect(DatesIst.sameDay(boundary, lateEvening.add(const Duration(hours: 2))), isFalse);
    });

    test('formats like the web', () {
      final t = DateTime.utc(2026, 9, 17, 13, 30); // 19:00 IST, a Thursday
      expect(DatesIst.day(t), 'Thu, 17 Sep');
      expect(DatesIst.shortDate(t), '17 Sep');
      expect(DatesIst.longDay(t), 'Thursday, 17 September');
      expect(DatesIst.time(t), '7:00 PM');
      expect(DatesIst.timeRange(l10n, t, const Duration(minutes: 90)), '7:00 PM – 8:30 PM IST');
      final parts = DatesIst.parts(t);
      expect([parts.day, parts.month, parts.weekday], ['17', 'Sep', 'Thu']);
    });

    test('labels times IST when the device is in another zone', () {
      final utcDevice = DateTime.utc(2026);
      expect(DatesIst.needsZoneLabel(deviceNow: utcDevice), isTrue);
      expect(
        DatesIst.dateTime(l10n, DateTime.utc(2026, 9, 17, 13, 30), deviceNow: utcDevice),
        '17 Sep 2026, 7:00 PM IST',
      );
    });

    test('greets by the IST hour', () {
      expect(
        DatesIst.greeting(l10n, Ist.instantFromWallClock(2026, 9, 22, 11, 59)),
        'Good morning',
      );
      expect(DatesIst.greeting(l10n, Ist.instantFromWallClock(2026, 9, 22, 12)), 'Good afternoon');
      expect(DatesIst.greeting(l10n, Ist.instantFromWallClock(2026, 9, 22, 17)), 'Good evening');
    });

    test('relative times use the web thresholds', () {
      final now = DateTime.utc(2026, 9, 22, 12);
      String rel(Duration d) => DatesIst.relative(l10n, now.add(d), now);
      expect(rel(const Duration(seconds: 30)), 'now');
      expect(rel(const Duration(minutes: 12)), 'in 12 minutes');
      expect(rel(const Duration(minutes: -1)), '1 minute ago');
      expect(rel(const Duration(hours: 3)), 'in 3 hours');
      expect(rel(const Duration(hours: -1)), '1 hour ago');
      expect(rel(const Duration(days: 1)), 'tomorrow');
      expect(rel(const Duration(days: -1)), 'yesterday');
      expect(rel(const Duration(days: 2)), 'in 2 days');
      expect(rel(const Duration(days: -5)), '5 days ago');
    });
  });

  group('Durations', () {
    test('minutes match the web', () {
      expect(AppDurations.minutes(l10n, 45), '45 min');
      expect(AppDurations.minutes(l10n, 60), '1h');
      expect(AppDurations.minutes(l10n, 65), '1h 05m');
      expect(AppDurations.minutes(l10n, 80.4), '1h 20m');
    });

    test('clock', () {
      expect(AppDurations.clock(245), '4:05');
      expect(AppDurations.clock(3725), '1:02:05');
      expect(AppDurations.clock(-3), '0:00');
    });
  });
}
