import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wall clock, behind a provider. Screens that move something on by time — a live class
/// opening its room — read it from here, so a test can drive time instead of waiting for it.
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

/// Time gone since the app started, on a monotonic clock: it only moves forward, whatever the
/// phone's wall clock is set to. A countdown the server set (a quiz's deadline) is measured on it
/// from the moment the server's answer arrived, never from the wall clock (§28.4.2).
typedef MonotonicClock = Duration Function();

final monotonicClockProvider = Provider<MonotonicClock>((ref) {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
});
