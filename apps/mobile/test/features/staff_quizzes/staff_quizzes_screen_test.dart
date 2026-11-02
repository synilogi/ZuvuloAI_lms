import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/platform/external_link.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_quizzes/staff_quizzes.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/$name.json'))) as Map<String, dynamic>;

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

UserProfile _instructor() => const UserProfile(
  id: 'u_staff',
  name: 'Dr. Meenakshi Iyer',
  email: 'staff@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({
    Map<String, dynamic>? list,
    Map<String, dynamic>? quiz,
    Map<String, dynamic>? stats,
    Object? listError,
    int listStatus = 200,
  }) {
    adapter.handler = (options) async {
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path.endsWith('/stats')) {
        return FakeAdapter.jsonResponse(stats ?? _json('quiz-stats'));
      }
      if (options.path == '/quizzes') {
        return listError == null
            ? FakeAdapter.jsonResponse(list ?? _json('quizzes'))
            : FakeAdapter.jsonResponse(listError, status: listStatus);
      }
      return FakeAdapter.jsonResponse(quiz ?? _json('quiz'));
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 4000),
    double textScale = 1,
    OpenExternalLink? openExternalLink,
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? _admin(),
    initialLocation: at,
    size: size,
    textScale: textScale,
    openExternalLink: openExternalLink,
    routes: [
      GoRoute(
        path: AppRoutes.staffQuizzes,
        builder: (_, _) => const Scaffold(body: SafeArea(child: StaffQuizzesScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffQuizPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(child: StaffQuizScreen(quizId: state.pathParameters['quizId'] ?? '')),
        ),
      ),
    ],
  );

  String quizId() => _json('quiz')['id'] as String;

  group('the list', () {
    testWidgets('shows each quiz with the academy\'s own figures', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();

      expect(find.byType(StaffQuizCard), findsNWidgets(2));
      expect(find.text('The Nine Planets: check your understanding'), findsOneWidget);
      expect(find.textContaining('3 questions · 30 points · 15 attempts'), findsOneWidget);
      expect(find.text('Pass rate: 67% · Average score: 68%'), findsOneWidget);
    });

    testWidgets('a status tab asks for that status alone', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Draft').first);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/quizzes').last.queryParameters['status'],
        'draft',
      );
    });

    testWidgets('searching narrows it', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'nakshatra');
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/quizzes').last.queryParameters['search'],
        'nakshatra',
      );
    });

    testWidgets('an academy with no quizzes is told where they are built', (tester) async {
      answering(
        list: {
          'rows': const <Object>[],
          'counts': const {'all': 0, 'draft': 0, 'published': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();

      expect(find.text('No quizzes yet'), findsOneWidget);
      expect(find.textContaining('built on the web'), findsOneWidget);
    });

    testWidgets('a filter that matches nothing offers to clear itself', (tester) async {
      answering(
        list: {
          'rows': const <Object>[],
          'counts': const {'all': 2, 'draft': 0, 'published': 2},
        },
      );

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft').first);
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('the course filter lives in the Filters sheet and asks for that course', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();
      expect(find.text('Course'), findsNothing, reason: 'not above the list');

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Course'));
      await tester.pumpAndSettle();
      final course =
          ((fixture('staff/courses.json')! as Map<String, dynamic>)['rows']! as List).first
              as Map<String, dynamic>;
      await tester.tap(find.text(course['title'] as String).last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/quizzes').last.queryParameters['courseId'],
        course['id'],
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Filters, 1 on'), findsOneWidget);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      answering(listError: const {'message': 'Server error.'}, listStatus: 500);

      await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();
      expect(find.byType(ErrorState), findsOneWidget);

      answering();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(StaffQuizCard), findsNWidgets(2));
    });

    testWidgets('the cards still fit on a narrow phone at the largest text size', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuizzes, size: const Size(360, 6000), textScale: 2);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffQuizCard), findsNWidgets(2));
    });

    testWidgets('opening a quiz goes to its own screen', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffQuizzes);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StaffQuizCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/quizzes/'));
    });
  });

  group('one quiz', () {
    testWidgets('reads out how it is set up', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuiz(quizId()));
      await tester.pumpAndSettle();

      expect(find.text('How it is set up'), findsOneWidget);
      expect(find.text('70%'), findsWidgets, reason: 'the pass mark');
      expect(find.text('3 attempts'), findsOneWidget);
      expect(find.text('No limit'), findsOneWidget);
      expect(
        find.text('Answers'),
        findsOneWidget,
        reason: 'options are shuffled, questions are not',
      );
      expect(find.text('Their score and the answers'), findsOneWidget);
    });

    testWidgets('shows the academy\'s figures and how the scores fell', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuiz(quizId()));
      await tester.pumpAndSettle();

      expect(find.text('Attempts'), findsWidgets);
      expect(find.text('15'), findsWidgets);
      expect(find.text('10'), findsWidgets, reason: 'ten learners behind fifteen attempts');
      expect(find.text('67%'), findsWidgets);
      expect(find.text('5 min'), findsWidgets);
      expect(find.text('How the scores fell'), findsOneWidget);
      // The bands are the server's own labels.
      expect(find.text('90–100%'), findsOneWidget);
    });

    testWidgets('every question shows its answer, marked as staff-only', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuiz(quizId()));
      await tester.pumpAndSettle();

      expect(find.text('The answers below are shown to staff only.'), findsOneWidget);
      expect(find.byType(StaffQuizQuestionCard), findsNWidgets(3));
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.text('Which house is considered a kendra?'), findsOneWidget);
      expect(find.text('1st house'), findsOneWidget);
      // A short answer lists what the academy accepts.
      expect(find.textContaining('Accepted:'), findsOneWidget);
    });

    testWidgets('a question says how learners did on it, and what they chose instead', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffQuiz(quizId()));
      await tester.pumpAndSettle();

      expect(find.textContaining('got it right'), findsWidgets);
      expect(find.textContaining('Most often chosen instead:'), findsWidgets);
    });

    testWidgets('a quiz nobody has taken says so instead of showing zeros', (tester) async {
      answering(
        stats: {
          'quizId': quizId(),
          'attempts': 0,
          'learners': 0,
          'passRate': 0,
          'avgScore': 0,
          'medianMinutes': 0,
          'distribution': const <Object>[],
          'questions': const <Object>[],
        },
      );

      await pump(tester, at: AppRoutes.staffQuiz(quizId()));
      await tester.pumpAndSettle();

      expect(find.text('No attempts yet'), findsOneWidget);
      expect(find.text('How the scores fell'), findsNothing);
      // The questions are still there to read.
      expect(find.byType(StaffQuizQuestionCard), findsNWidgets(3));
    });

    testWidgets('"Edit on the web" opens the editor for the role', (tester) async {
      answering();
      final opened = <Uri>[];

      await pump(
        tester,
        at: AppRoutes.staffQuiz(quizId()),
        signedInAs: _instructor(),
        openExternalLink: (link) async => opened.add(link),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit on the web'));
      await tester.pumpAndSettle();

      expect(opened.single.path, startsWith('/teach/courses/'));
    });

    testWidgets('a quiz that is not this account\'s reads as not found', (tester) async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Quiz not found.'}, status: 404);

      await pump(tester, at: AppRoutes.staffQuiz('someone-elses'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });

    testWidgets('everything still fits at the largest text size', (tester) async {
      answering();

      await pump(
        tester,
        at: AppRoutes.staffQuiz(quizId()),
        size: const Size(400, 9000),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
