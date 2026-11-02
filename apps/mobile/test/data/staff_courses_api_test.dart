import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late StaffCoursesApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffCoursesApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the list asks for one page and nothing the screen did not narrow by', () async {
    adapter.enqueueJson(fixture('staff/courses.json'));

    await api.courses();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/courses');
    expect(adapter.lastRequest.queryParameters, {'page': 1, 'pageSize': 20});
  });

  test('every filter the screen offers travels as the route names it', () async {
    adapter.enqueueJson(fixture('staff/courses.json'));

    await api.courses(
      search: 'nakshatra',
      categoryId: 'cat_1',
      instructorId: 'ins_1',
      status: 'draft',
      sort: 'learners',
      page: 3,
    );

    expect(adapter.lastRequest.queryParameters, {
      'search': 'nakshatra',
      'categoryId': 'cat_1',
      'instructorId': 'ins_1',
      'status': 'draft',
      'sort': 'learners',
      'page': 3,
      'pageSize': 20,
    });
  });

  test('a course id is escaped into the path, never interpolated raw', () async {
    adapter.enqueueJson(
      ((fixture('staff/courses.json')! as Map<String, dynamic>)['rows']! as List).first,
    );

    await api.course('a b/c');

    expect(adapter.lastRequest.path, '/courses/a%20b%2Fc');
  });

  test('the stats, the curriculum stats and the lessons each have their own path', () async {
    adapter
      ..enqueueJson(fixture('staff/course-stats.json'))
      ..enqueueJson(fixture('staff/chapter-stats.json'))
      ..enqueueJson(fixture('staff/course-lessons.json'));

    await api.stats('c1');
    expect(adapter.lastRequest.path, '/courses/c1/stats');

    await api.curriculumStats('c1');
    expect(adapter.lastRequest.path, '/courses/c1/chapters/stats');

    await api.lessons('c1', chapterId: 'ch1', search: 'moon');
    expect(adapter.lastRequest.path, '/courses/c1/lessons');
    expect(adapter.lastRequest.queryParameters, {'chapterId': 'ch1', 'search': 'moon'});
  });

  test('one lesson comes back with its chapter and its neighbours', () async {
    final row =
        ((fixture('staff/course-lessons.json')! as Map<String, dynamic>)['rows']! as List).first;
    adapter.enqueueJson({
      ...row as Map<String, dynamic>,
      'previous': const {'id': 'l0', 'title': 'Before'},
      'next': const {'id': 'l2', 'title': 'After'},
    });

    final detail = await api.lesson('c1', 'l1');

    expect(adapter.lastRequest.path, '/courses/c1/lessons/l1');
    expect(detail.lesson.title, isNotEmpty);
    expect(detail.previous!.title, 'Before');
    expect(detail.next!.id, 'l2');
  });

  test('every lifecycle action is a POST to its own verb, with no body at all', () async {
    final course =
        ((fixture('staff/courses.json')! as Map<String, dynamic>)['rows']! as List).first;
    for (var i = 0; i < 4; i++) {
      adapter.enqueueJson(course);
    }

    await api.publish('c1');
    expect(adapter.lastRequest.path, '/courses/c1/publish');
    await api.unpublish('c1');
    expect(adapter.lastRequest.path, '/courses/c1/unpublish');
    await api.archive('c1');
    expect(adapter.lastRequest.path, '/courses/c1/archive');
    await api.restore('c1');
    expect(adapter.lastRequest.path, '/courses/c1/restore');

    for (final request in adapter.requests.where((r) => r.method == 'POST')) {
      expect(request.data, isNull, reason: 'the academy decides; the app sends no state');
    }
  });

  test('the categories are read whole, with no query', () async {
    adapter.enqueueJson(fixture('staff/categories.json'));

    final page = await api.categories();

    expect(adapter.lastRequest.path, '/categories');
    expect(adapter.lastRequest.queryParameters, isEmpty);
    expect(page.rows, isNotEmpty);
  });
}
