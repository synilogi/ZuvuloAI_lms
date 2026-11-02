import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/shared/domain/dashboard.dart';

/// `kpiChange` (`packages/domain/src/analytics.ts`), ported. A count moves in percent; a rate
/// moves in points, so 60% → 63% reads +3 pts and never +5%.
Kpi count(num value, num previous) => Kpi(value: value, previous: previous);

Kpi rate(num value, num previous) => Kpi(value: value, previous: previous, unit: KpiUnit.percent);

void main() {
  test('a count that grew reads as a percentage, rounded to one place', () {
    final change = kpiChange(count(52, 43));

    expect(change.direction, TrendDirection.up);
    expect(change.amount, 20.9);
    expect(change.isPoints, isFalse);
  });

  test('a count that shrank reads the same way, without a sign in the amount', () {
    final change = kpiChange(count(43, 52));

    expect(change.direction, TrendDirection.down);
    expect(change.amount, 17.3);
    expect(change.isPoints, isFalse);
  });

  test('a count that did not move is flat', () {
    expect(kpiChange(count(6, 6)).direction, TrendDirection.flat);
    expect(kpiChange(count(6, 6)).amount, 0);
  });

  test('a rate moves in points, not percent', () {
    final up = kpiChange(rate(63, 60));
    expect(up.direction, TrendDirection.up);
    expect(up.amount, 3);
    expect(up.isPoints, isTrue, reason: '60% → 63% is +3 pts, not +5%');

    final down = kpiChange(rate(58, 59));
    expect(down.direction, TrendDirection.down);
    expect(down.amount, 1);
    expect(down.isPoints, isTrue);

    expect(kpiChange(rate(58, 58)).direction, TrendDirection.flat);
  });

  test('a rate rounds to one place, as the server does', () {
    expect(kpiChange(rate(58.44, 58)).amount, 0.4);
    expect(kpiChange(rate(58.46, 58)).amount, 0.5);
  });

  test('growing from nothing is a hundred percent, and staying at nothing is flat', () {
    final fromZero = kpiChange(count(2, 0));
    expect(fromZero.direction, TrendDirection.up);
    expect(fromZero.amount, 100);
    expect(fromZero.isPoints, isFalse);

    final stillZero = kpiChange(count(0, 0));
    expect(stillZero.direction, TrendDirection.flat);
    expect(stillZero.amount, 0);
  });

  test('a rate that starts at zero still compares in points', () {
    final change = kpiChange(rate(12, 0));

    expect(change.amount, 12);
    expect(change.isPoints, isTrue, reason: 'the zero-previous shortcut is for counts only');
  });
}
