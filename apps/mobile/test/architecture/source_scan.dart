import 'dart:io';

/// Helpers shared by the architecture tests. `flutter test` runs with the package root as the
/// working directory, so paths are package-relative.

/// Every hand-written Dart file under [root] (generated `*.g.dart` / `*.freezed.dart` and
/// generated localizations are skipped).
List<File> dartSources([String root = 'lib']) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .where((f) => !f.path.endsWith('.freezed.dart'))
      .where((f) => !f.path.contains('/l10n/generated/'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Normalises a path to forward slashes relative to the package root.
String relativePath(File file) => file.path.replaceAll(r'\', '/').replaceFirst('./', '');

/// Source with `//` line comments and `/* */` block comments removed, keeping line numbers.
String stripComments(String source) {
  final withoutBlocks = source.replaceAllMapped(
    RegExp(r'/\*[\s\S]*?\*/'),
    (m) => '\n' * '\n'.allMatches(m.group(0)!).length,
  );
  return withoutBlocks
      .split('\n')
      .map((line) {
        final index = _lineCommentStart(line);
        return index == -1 ? line : line.substring(0, index);
      })
      .join('\n');
}

/// Index of a `//` that starts a comment (not one inside a string literal), or -1.
int _lineCommentStart(String line) {
  String? quote;
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == r'\') {
        i++;
      } else if (c == quote) {
        quote = null;
      }
    } else if (c == "'" || c == '"') {
      quote = c;
    } else if (c == '/' && line[i + 1] == '/') {
      return i;
    }
  }
  return -1;
}

/// A rule violation: where it is and what matched.
class Violation {
  const Violation(this.path, this.line, this.text);

  final String path;
  final int line;
  final String text;

  @override
  String toString() => '$path:$line  $text';
}

/// Every line of [source] (comments stripped) that matches any of [patterns].
List<Violation> findMatches(String path, String source, List<RegExp> patterns) {
  final lines = stripComments(source).split('\n');
  final found = <Violation>[];
  for (var i = 0; i < lines.length; i++) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lines[i]);
      if (match != null) {
        found.add(Violation(path, i + 1, match.group(0)!.trim()));
        break;
      }
    }
  }
  return found;
}
