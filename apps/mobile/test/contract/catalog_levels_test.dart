import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/network/json.dart';
import 'package:syniastrolms_mobile/shared/domain/level.dart';

/// Contract test (§23): the model parses the response the **real** API returned, captured by
/// `tool/capture_fixture.sh GET /catalog/levels none catalog/levels.json`.
void main() {
  final fixture =
      jsonDecode(File('test/fixtures/catalog/levels.json').readAsStringSync()) as List<dynamic>;

  test('Level parses every row of the captured /catalog/levels response', () {
    final levels = [
      for (final row in asJsonList('/catalog/levels', fixture))
        Level.fromJson(row as Map<String, dynamic>),
    ];

    expect(levels, isNotEmpty);
    expect(levels.map((l) => l.name), contains('Beginner'));
    expect(levels.first.order, 1);
    expect(levels.every((l) => l.id.isNotEmpty), isTrue);
  });

  test('round-trips through JSON', () {
    final level = Level.fromJson(fixture.first as Map<String, dynamic>);
    expect(Level.fromJson(level.toJson()), level);
  });

  test('an optional summary may be absent', () {
    const level = Level(id: 'l1', name: 'Beginner', order: 1);
    expect(level.summary, isNull);
    expect(Level.fromJson(const {'id': 'l1', 'name': 'Beginner', 'order': 1}), level);
  });
}
