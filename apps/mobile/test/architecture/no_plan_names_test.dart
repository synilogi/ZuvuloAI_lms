import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// What an academy may do is what the backend says its plan grants — never which plan it is on
/// (modules.md §7, §9.3). Mirrors the backend's ESLint `PLAN_NAME_CHECKS`: no comparison against,
/// and no `switch` on, a plan's `code`/`name` or a `planCode`/`planName` value.
const _planValue =
    r'(?:\b(?:\w+\s*\??\.\s*)*\w*plan\w*\s*\??\.\s*(?:code|name)\b|\bplan(?:Code|Name)\b)';

final planNamePatterns = [
  RegExp('$_planValue\\s*[!=]=', caseSensitive: false),
  RegExp('[!=]=\\s*$_planValue', caseSensitive: false),
  RegExp('switch\\s*\\(\\s*$_planValue', caseSensitive: false),
];

void main() {
  test('no plan-name or plan-code checks in lib/', () {
    final violations = [
      for (final file in dartSources())
        ...findMatches(relativePath(file), file.readAsStringSync(), planNamePatterns),
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('detector catches plan-name checks', () {
    const sample = '''
if (billing.plan.code == 'PRO') {}
if ('Growth' != current.plan?.name) {}
if (planName == 'Starter') {}
switch (subscription.plan.code) {}
final label = plan.name; // display is fine
if (course.name == 'x') {}
''';
    expect(findMatches('sample.dart', sample, planNamePatterns).map((v) => v.line), [1, 2, 3, 4]);
  });
}
