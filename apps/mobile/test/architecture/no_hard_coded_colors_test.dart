import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// Colours come from the design tokens (modules.md §22.2): no hex or `Colors.*` values outside
/// `lib/core/theme/tokens.dart`. `Colors.transparent` is not a colour choice and is allowed.
final colorPatterns = [
  RegExp(r'Color\(\s*0x[0-9A-Fa-f]'),
  RegExp(r'Color\.from(ARGB|RGBO)\('),
  RegExp(r'\bColors\.(?!transparent\b)[a-zA-Z]'),
  RegExp(r'''['"]#[0-9A-Fa-f]{6,8}['"]'''),
];

void main() {
  test('no hard-coded colours outside lib/core/theme/tokens.dart', () {
    final violations = [
      for (final file in dartSources())
        if (relativePath(file) != 'lib/core/theme/tokens.dart')
          ...findMatches(relativePath(file), file.readAsStringSync(), colorPatterns),
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('detector catches hard-coded colours', () {
    const sample = '''
final a = Color(0xFF5E3FAF);
final b = Colors.red;
final c = Color.fromARGB(255, 0, 0, 0);
final d = '#5E3FAF';
final ok = Colors.transparent; // Colors.blue in a comment is fine
''';
    expect(findMatches('sample.dart', sample, colorPatterns).map((v) => v.line), [1, 2, 3, 4]);
  });
}
