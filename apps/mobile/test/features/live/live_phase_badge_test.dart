import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/live/live.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/public_harness.dart';

/// A class from the captured schedule, with or without a kept recording.
LiveClass _class({required bool recorded}) {
  final raw = jsonDecode(jsonEncode(fixture('live/learner.json'))) as Map<String, dynamic>;
  final row = (raw['upcoming']! as List<dynamic>).first as Map<String, dynamic>;
  final cls = Map<String, dynamic>.of(row['liveClass']! as Map<String, dynamic>);
  if (recorded) {
    cls['recording'] = {'durationMin': 60, 'availableUntil': '2026-01-01T00:00:00.000Z'};
  } else {
    cls.remove('recording');
  }
  return LiveClass.fromJson(cls);
}

void main() {
  test('a class that was never recorded reads "Ended", not "Recording expired"', () {
    expect(livePhaseBadge(LivePhase.recordingExpired, _class(recorded: false)), StatusKind.ended);
  });

  test('a recording past its date still reads "Recording expired"', () {
    expect(
      livePhaseBadge(LivePhase.recordingExpired, _class(recorded: true)),
      StatusKind.recordingExpired,
    );
  });

  test('without the class, the phase alone decides, as before', () {
    expect(livePhaseBadge(LivePhase.recordingExpired), StatusKind.recordingExpired);
  });
}
