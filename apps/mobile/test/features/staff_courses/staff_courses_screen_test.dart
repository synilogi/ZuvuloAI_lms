import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/platform/external_link.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _courses() =>
    jsonDecode(jsonEncode(fixture('staff/courses.json'))) as Map<String, dynamic>;

Map<String, dynamic> _course([int index = 0]) =>
    (_courses()['rows']! as List)[index] as Map<String, dynamic>;

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

  /// Answers every read the screens make, by path.
  void answering({
    Map<String, dynamic>? list,
    Map<String, dynamic>? course,
    Object? listError,
    int listStatus = 200,
    Object? action,
    int actionStatus = 200,
    String? plan,
  }) {
    adapter.handler = (options) async {
      if (plan != null && options.path == '/academy/plan') {
        return FakeAdapter.jsonResponse(fixture('entitlements/$plan'));
      }
      if (options.method == 'POST') {
        return FakeAdapter.jsonResponse(action ?? course ?? _course(), status: actionStatus);
      }
      if (options.path == '/categories') {
        return FakeAdapter.jsonResponse(fixture('staff/categories.json'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      if (options.path.endsWith('/chapters/stats')) {
        return FakeAdapter.jsonResponse(fixture('staff/chapter-stats.json'));
      }
      if (options.path.endsWith('/stats')) {
        return FakeAdapter.jsonResponse(fixture('staff/course-stats.json'));
      }
      if (options.path == '/courses') {
        return listError == null
            ? FakeAdapter.jsonResponse(list ?? _courses())
            : FakeAdapter.jsonResponse(listError, status: listStatus);
      }
      return FakeAdapter.jsonResponse(course ?? _course());
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 2400),
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
        path: AppRoutes.staffCourses,
        builder: (_, _) => const Scaffold(body: SafeArea(child: StaffCoursesScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffCoursePattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: StaffCourseScreen(courseId: state.pathParameters['courseId'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffCurriculumPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: CourseCurriculumScreen(courseId: state.pathParameters['courseId'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffLessonPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: StaffLessonScreen(
              courseId: state.pathParameters['courseId'] ?? '',
              lessonId: state.pathParameters['lessonId'] ?? '',
            ),
          ),
        ),
      ),
    ],
  );

  group('the list', () {
    testWidgets('shows the academy\'s courses with the counts it sent', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();

      expect(find.byType(StaffCourseCard), findsNWidgets(6));
      expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
      // The tabs carry the academy's counts, not the number of rows on screen.
      expect(find.textContaining('6'), findsWidgets);
      expect(find.text('Published'), findsWidgets);
    });

    testWidgets('searching asks the academy again, narrowed', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'nakshatra');
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/courses').last.queryParameters['search'],
        'nakshatra',
      );
    });

    testWidgets('a status tab asks for that status alone', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Draft').first);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/courses').last.queryParameters['status'],
        'draft',
      );
    });

    testWidgets('an academy with no courses is told where they are made', (tester) async {
      answering(
        list: {
          'rows': const <Object>[],
          'total': 0,
          'counts': const {'all': 0, 'draft': 0, 'published': 0, 'archived': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();

      expect(find.text('No courses yet'), findsOneWidget);
      expect(find.textContaining('created on the web'), findsOneWidget);
    });

    testWidgets('a filter that matches nothing offers to clear itself', (tester) async {
      answering(
        list: {
          'rows': const <Object>[],
          'total': 0,
          'counts': const {'all': 6, 'draft': 0, 'published': 6, 'archived': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();
      // The tabs scroll sideways on a phone; the last one starts off the edge.
      await tester.scrollUntilVisible(
        find.text('Archived'),
        120,
        scrollable: find.descendant(
          of: find.byType(FilterChipBar<String>),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(
        adapter.requests
            .where((r) => r.path == '/courses')
            .last
            .queryParameters
            .containsKey('status'),
        isFalse,
      );
    });

    testWidgets('an instructor is offered no instructor filter', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourses, signedInAs: _instructor());
      await tester.pumpAndSettle();
      // The secondary filters live behind the Filters button.
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Instructor'), findsNothing);
      expect(find.text('Category'), findsOneWidget);
    });

    testWidgets('an admin narrows by instructor and sorts from the Filters sheet', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing, reason: 'the selects are not above the list');

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Instructor'), findsOneWidget);

      await tester.tap(find.text('Sort by'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learners').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/courses').last.queryParameters['sort'],
        'learners',
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      // The button says a filter is on, and clearing it puts the order back.
      expect(find.byTooltip('Filters, 1 on'), findsOneWidget);
      await tester.tap(find.byTooltip('Filters, 1 on'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/courses').last.queryParameters['sort'],
        'updated',
      );
      expect(find.byTooltip('Filters'), findsOneWidget);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      answering(listError: const {'message': 'Server error.'}, listStatus: 500);

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();
      expect(find.byType(ErrorState), findsOneWidget);

      answering();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(StaffCourseCard), findsNWidgets(6));
    });

    testWidgets('a long catalogue is paged, and the page travels with the request', (tester) async {
      final many = _courses();
      many['total'] = 42;
      answering(list: many);

      await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();

      expect(find.text('Page 1 of 3'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Next'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.path == '/courses').last.queryParameters['page'], 2);
      expect(find.text('Page 2 of 3'), findsOneWidget);
    });

    testWidgets('the cards still fit on a narrow phone at the largest text size', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourses, size: const Size(360, 8000), textScale: 2);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffCourseCard), findsNWidgets(6));
    });

    testWidgets('opening a course goes to its own screen', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffCourses);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StaffCourseCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/courses/'));
    });
  });

  group('one course', () {
    testWidgets('shows the academy\'s figures for it', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourse(_course()['id'] as String));
      await tester.pumpAndSettle();

      expect(find.text('How it is going'), findsOneWidget);
      expect(find.text('17'), findsWidgets, reason: 'enrolled, as the server counted it');
      expect(find.text('41%'), findsWidgets, reason: 'the completion rate it sent');
      expect(find.text('How far learners have got'), findsOneWidget);
    });

    testWidgets('a published course can be unpublished or archived, not published again', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourse(_course()['id'] as String));
      await tester.pumpAndSettle();

      expect(find.text('Unpublish'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Publish'), findsNothing);
    });

    testWidgets('publishing a draft is confirmed first, then the academy is asked', (tester) async {
      final draft = _course()..['status'] = 'draft';
      answering(course: draft);

      await pump(tester, at: AppRoutes.staffCourse(draft['id'] as String));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(find.text('Take this course live?'), findsOneWidget);

      answering(course: _course());
      await tester.tap(find.widgetWithText(AppButton, 'Publish').last);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'POST').last.path, endsWith('/publish'));
      expect(find.text('The course is live'), findsOneWidget);
    });

    testWidgets('while the plan that had courses has ended, Publish is disabled and says why', (
      tester,
    ) async {
      final draft = _course()..['status'] = 'draft';
      answering(course: draft, plan: 'academy-plan-lapsed.json');

      await pump(tester, at: AppRoutes.staffCourse(draft['id'] as String));
      for (var i = 0; i < 3; i++) {
        await tester.pump(Duration.zero);
        await tester.pumpAndSettle();
      }

      final publish = find.widgetWithText(AppButton, 'Publish');
      expect(publish, findsOneWidget);
      expect(tester.widget<AppButton>(publish).onPressed, isNull);
      expect(find.text('Adding to Courses needs an active plan.'), findsOneWidget);
      // Taking a course away from learners is still allowed.
      expect(find.text('Archive'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a publish the academy refuses shows its checklist, in its words', (tester) async {
      final draft = _course()..['status'] = 'draft';
      answering(course: draft, action: fixture('errors/publish-checklist.json'), actionStatus: 409);

      await pump(tester, at: AppRoutes.staffCourse(draft['id'] as String));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Publish').last);
      await tester.pumpAndSettle();

      expect(find.text('Not ready to publish yet'), findsOneWidget);
      expect(find.text('Five or more lessons'), findsOneWidget);
      expect(find.text('A published chapter with lessons'), findsOneWidget);
    });

    testWidgets('archiving asks for an acknowledgement before it will go ahead', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffCourse(_course()['id'] as String));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Archive this course?'), findsOneWidget);
      final confirm = find.widgetWithText(AppButton, 'Archive').last;
      expect(tester.widget<AppButton>(confirm).onPressed, isNull, reason: 'not yet acknowledged');

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'POST').last.path, endsWith('/archive'));
    });

    testWidgets('an archived course is offered a restore', (tester) async {
      final archived = _course()..['status'] = 'archived';
      answering(course: archived);

      await pump(tester, at: AppRoutes.staffCourse(archived['id'] as String));
      await tester.pumpAndSettle();

      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Publish'), findsNothing, reason: 'it must come back before it can go live');
    });

    testWidgets('an admin without the catalogue keys is offered no lifecycle action', (
      tester,
    ) async {
      answering();
      const reader = UserProfile(
        id: 'u_reader',
        name: 'Reader',
        email: 'reader@example.test',
        role: UserRole.admin,
        descriptor: 'Academy admin',
        permissions: [PermissionKey.catalogView],
      );

      await pump(tester, at: AppRoutes.staffCourse(_course()['id'] as String), signedInAs: reader);
      await tester.pumpAndSettle();

      expect(find.text('Unpublish'), findsNothing);
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Edit on the web'), findsOneWidget);
    });

    testWidgets('"Edit on the web" opens the admin\'s own editor', (tester) async {
      answering();
      final opened = <Uri>[];

      await pump(
        tester,
        at: AppRoutes.staffCourse(_course()['id'] as String),
        openExternalLink: (link) async => opened.add(link),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit on the web'));
      await tester.pumpAndSettle();

      expect(opened.single.toString(), 'https://web.test/admin/courses/${_course()['id']}/edit');
    });

    testWidgets('an instructor is sent to the teaching side of the web instead', (tester) async {
      answering();
      final opened = <Uri>[];

      await pump(
        tester,
        at: AppRoutes.staffCourse(_course()['id'] as String),
        signedInAs: _instructor(),
        openExternalLink: (link) async => opened.add(link),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit on the web'));
      await tester.pumpAndSettle();

      expect(opened.single.toString(), 'https://web.test/teach/courses/${_course()['id']}/edit');
    });

    testWidgets('a course that is not this account\'s reads as not found', (tester) async {
      adapter.handler = (options) async => options.path.endsWith('/stats')
          ? FakeAdapter.jsonResponse(fixture('staff/course-stats.json'))
          : FakeAdapter.jsonResponse(const {'message': 'Course not found.'}, status: 404);

      await pump(tester, at: AppRoutes.staffCourse('someone-elses'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });

    testWidgets('everything still fits at the largest text size', (tester) async {
      answering();

      await pump(
        tester,
        at: AppRoutes.staffCourse(_course()['id'] as String),
        size: const Size(400, 6000),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('the curriculum', () {
    testWidgets('lists the chapters with how far learners have got', (tester) async {
      answering(course: _course(3));

      await pump(tester, at: AppRoutes.staffCurriculum(_course(3)['id'] as String));
      await tester.pumpAndSettle();

      expect(find.byType(CurriculumChapterCard), findsWidgets);
      expect(find.textContaining('started ·'), findsWidgets);
      expect(find.textContaining('completed it'), findsWidgets);
    });

    testWidgets('a course with no chapters says so rather than showing nothing', (tester) async {
      final empty = _course()..['chapters'] = <Object>[];
      answering(course: empty);

      await pump(tester, at: AppRoutes.staffCurriculum(empty['id'] as String));
      await tester.pumpAndSettle();

      expect(find.textContaining('No chapters yet'), findsOneWidget);
    });

    testWidgets('opening a lesson goes to the lesson', (tester) async {
      answering(course: _course(3));

      final router = await pump(tester, at: AppRoutes.staffCurriculum(_course(3)['id'] as String));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppListTile).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), contains('/lessons/'));
    });
  });

  group('one lesson', () {
    Map<String, dynamic> lessonDetail({bool withNeighbours = true}) {
      final row = jsonDecode(
        jsonEncode(
          ((fixture('staff/course-lessons.json')! as Map<String, dynamic>)['rows']! as List).first,
        ),
      );
      return {
        ...row as Map<String, dynamic>,
        if (withNeighbours) 'previous': const {'id': 'l0', 'title': 'Before'},
        if (withNeighbours) 'next': const {'id': 'l2', 'title': 'After'},
      };
    }

    testWidgets('shows what the lesson is and where it sits', (tester) async {
      final detail = lessonDetail();
      adapter.handler = (options) async => options.path.endsWith('/chapters/stats')
          ? FakeAdapter.jsonResponse(fixture('staff/chapter-stats.json'))
          : FakeAdapter.jsonResponse(detail);

      await pump(tester, at: AppRoutes.staffLesson('c1', 'l1'));
      await tester.pumpAndSettle();

      expect(find.text('Introduction to the Navagrahas'), findsOneWidget);
      expect(find.text('The Nine Planets'), findsOneWidget);
      expect(find.text('Free preview'), findsOneWidget);
    });

    testWidgets('moves to the neighbour the academy named', (tester) async {
      adapter.handler = (options) async => FakeAdapter.jsonResponse(lessonDetail());

      final router = await pump(tester, at: AppRoutes.staffLesson('c1', 'l1'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Next'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffLesson('c1', 'l2'));
    });

    testWidgets('the first lesson has nothing before it', (tester) async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(lessonDetail(withNeighbours: false));

      await pump(tester, at: AppRoutes.staffLesson('c1', 'l1'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AppButton>(find.widgetWithText(AppButton, 'Previous')).onPressed,
        isNull,
      );
    });

    testWidgets('the lesson still fits on a narrow phone at the largest text size', (tester) async {
      adapter.handler = (options) async => options.path.endsWith('/chapters/stats')
          ? FakeAdapter.jsonResponse(fixture('staff/chapter-stats.json'))
          : FakeAdapter.jsonResponse(lessonDetail());

      await pump(
        tester,
        at: AppRoutes.staffLesson('c1', 'l1'),
        size: const Size(360, 6000),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a lesson the academy sent nothing for says so', (tester) async {
      final detail = lessonDetail();
      (detail['lesson']! as Map<String, dynamic>)['content'] = <String, Object?>{};
      adapter.handler = (options) async => FakeAdapter.jsonResponse(detail);

      await pump(tester, at: AppRoutes.staffLesson('c1', 'l1'));
      await tester.pumpAndSettle();

      expect(find.text('This lesson has nothing in it yet.'), findsOneWidget);
    });
  });
}
