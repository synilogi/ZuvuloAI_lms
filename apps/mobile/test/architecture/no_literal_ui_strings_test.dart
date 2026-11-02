import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// User-facing copy lives in the ARB files (modules.md §21): no English literals in widgets.
/// The dev-only component gallery (`lib/dev/`) is exempt, as are brand-name constants.
final literalUiPatterns = [
  RegExp(r'''\bText\(\s*(['"])(.*?)\1'''),
  RegExp(
    r'''\b(tooltip|labelText|hintText|helperText|errorText|semanticLabel|semanticsLabel)\s*:\s*(['"])(.*?)\2''',
  ),
];

/// True when the literal holds words, not just interpolation or punctuation.
bool _hasWords(String literal) =>
    RegExp('[A-Za-z]').hasMatch(literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), ''));

List<Violation> literalUiStrings(String path, String source) {
  return findMatches(path, source, literalUiPatterns).where((v) {
    final match = RegExp(r'''(['"])(.*?)\1''').firstMatch(v.text);
    return match != null && _hasWords(match.group(2)!);
  }).toList();
}

void main() {
  test('no literal UI strings in lib/ widgets', () {
    final violations = [
      for (final file in dartSources())
        if (!relativePath(file).startsWith('lib/dev/'))
          ...literalUiStrings(relativePath(file), file.readAsStringSync()),
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('detector catches literal copy and ignores interpolation', () {
    const sample = '''
Text('Sign in'),
IconButton(tooltip: "Close", onPressed: close),
Text('\$count'),
Text(l10n.signIn),
Text('\${lesson.number} · '),
TextField(decoration: InputDecoration(labelText: 'Email')),
''';
    expect(literalUiStrings('sample.dart', sample).map((v) => v.line), [1, 2, 6]);
  });
}
