import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// The quiz answer key never reaches learner code (§18, §28.4, FLUTTER-021).
///
/// `GET /quizzes/:id` serves staff the whole quiz, `correct` and `acceptedAnswers` included, so the
/// staff model is a separate DTO from the learner's. Only a `staff_*` feature may read it: a
/// learner screen that could reach it could show an answer, and a learner-facing model that grew a
/// `correct` field would be scored in the app rather than on the server.
const _staffQuizFeature = 'lib/features/staff_quizzes/';
final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Resolved import targets of [path], as `lib/`-relative paths.
Iterable<String> importsOf(String path, String source) =>
    _import.allMatches(source).map((m) => m.group(1)!).map((uri) => _resolve(path, uri));

String _resolve(String fromPath, String uri) {
  if (uri.startsWith('package:syniastrolms_mobile/')) {
    return 'lib/${uri.substring('package:syniastrolms_mobile/'.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return uri;
  final segments = fromPath.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '..') {
      segments.removeLast();
    } else if (part != '.') {
      segments.add(part);
    }
  }
  return segments.join('/');
}

/// Whether [path] is allowed to read the staff quiz model: a `staff_*` feature, or `lib/app/`,
/// which wires every feature's screens into the router and reads none of their data.
bool mayReadTheAnswerKey(String path) =>
    path.startsWith('lib/app/') || RegExp(r'^lib/features/staff_[^/]+/').hasMatch(path);

/// Every file that reaches the staff quiz model from somewhere it may not.
List<String> answerKeyReaches(String path, String source) {
  if (mayReadTheAnswerKey(path)) return const [];
  return [
    for (final target in importsOf(path, source))
      if (target.startsWith(_staffQuizFeature)) '$path reads the staff quiz model ($target)',
  ];
}

void main() {
  test('only staff features can reach the staff quiz model', () {
    final problems = <String>[];
    for (final file in dartSources()) {
      problems.addAll(answerKeyReaches(relativePath(file), file.readAsStringSync()));
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the learner quiz model has no answer key at all', () {
    final source = stripComments(
      dartSources()
          .singleWhere((f) => relativePath(f) == 'lib/shared/domain/quiz.dart')
          .readAsStringSync(),
    );

    for (final field in ['correct', 'acceptedAnswers', 'explanation']) {
      expect(
        source,
        isNot(contains(field)),
        reason: 'lib/shared/domain/quiz.dart must not model $field — scoring is the server\'s',
      );
    }
  });

  group('detector', () {
    test('flags a learner screen reaching the staff model', () {
      expect(
        answerKeyReaches(
          'lib/features/assessments/presentation/screens/quiz_screen.dart',
          "import '../../../staff_quizzes/staff_quizzes.dart';",
        ),
        isNotEmpty,
      );
      expect(
        answerKeyReaches(
          'lib/features/assessments/application/quiz_controller.dart',
          "import 'package:syniastrolms_mobile/features/staff_quizzes/data/dto/staff_quiz.dart';",
        ),
        isNotEmpty,
      );
    });

    test('allows a staff feature to read it', () {
      expect(
        answerKeyReaches(
          'lib/features/staff_quizzes/presentation/screens/staff_quiz_screen.dart',
          "import '../../application/staff_quizzes_controller.dart';",
        ),
        isEmpty,
      );
      expect(
        answerKeyReaches(
          'lib/features/staff_dashboard/application/dashboard_controller.dart',
          "import '../../staff_quizzes/staff_quizzes.dart';",
        ),
        isEmpty,
      );
    });

    test('allows the router, which only builds the screen', () {
      expect(
        answerKeyReaches(
          'lib/app/routing/app_router.dart',
          "import '../../features/staff_quizzes/staff_quizzes.dart';",
        ),
        isEmpty,
      );
    });

    test('ignores a learner file that imports the learner model', () {
      expect(
        answerKeyReaches(
          'lib/features/assessments/application/quiz_controller.dart',
          "import '../../../shared/domain/quiz.dart';",
        ),
        isEmpty,
      );
    });
  });
}
