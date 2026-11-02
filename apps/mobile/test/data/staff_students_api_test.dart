import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/staff_students/staff_students.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late StaffStudentsApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = StaffStudentsApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('the roster asks for one page and nothing the screen did not narrow by', () async {
    adapter.enqueueJson(fixture('staff/students.json'));

    await api.students();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/students');
    expect(adapter.lastRequest.queryParameters, {'page': 1, 'pageSize': 20});
  });

  test('every filter travels as the route names it', () async {
    adapter.enqueueJson(fixture('staff/students.json'));

    await api.students(
      search: 'ananya',
      courseId: 'c1',
      status: 'at-risk',
      sort: 'progress',
      page: 2,
    );

    expect(adapter.lastRequest.queryParameters, {
      'search': 'ananya',
      'courseId': 'c1',
      'status': 'at-risk',
      'sort': 'progress',
      'page': 2,
      'pageSize': 20,
    });
  });

  test('a learner id is escaped into the path, never interpolated raw', () async {
    adapter.enqueueJson(fixture('staff/student.json'));

    await api.student('a b/c');

    expect(adapter.lastRequest.path, '/students/a%20b%2Fc');
  });

  test('the progress and the activity each have their own path', () async {
    adapter
      ..enqueueJson(fixture('staff/student-progress.json'))
      ..enqueueJson(fixture('staff/student-activity.json'));

    await api.progress('s1');
    expect(adapter.lastRequest.path, '/students/s1/progress');

    await api.activity('s1', kind: 'lesson-completed', courseId: 'c1');
    expect(adapter.lastRequest.path, '/students/s1/activity');
    expect(adapter.lastRequest.queryParameters, {'kind': 'lesson-completed', 'courseId': 'c1'});
  });

  test('a message names the learners and the channels, and reports the academy\'s count', () async {
    adapter.enqueueJson(const {'sent': 2});

    final sent = await api.message(
      studentIds: const ['s1', 's2'],
      subject: 'A note about next week',
      body: 'The live class moves to Thursday. Bring your charts.',
      channels: const {'app', 'email'},
    );

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/students/message');
    final body = adapter.lastRequest.data! as Map;
    expect(body['ids'], const ['s1', 's2']);
    expect(body['subject'], 'A note about next week');
    expect(body['channels'], containsAll(['app', 'email']));
    expect(sent, 2);
  });

  test('enrolling sends the course and the source, and never a price or an expiry', () async {
    adapter.enqueueJson(
      (((fixture('staff/student.json')! as Map<String, dynamic>)['enrollments']! as List).first
          as Map<String, dynamic>)['enrollment'],
    );

    await api.enroll('s1', courseId: 'c1');

    expect(adapter.lastRequest.path, '/students/s1/enroll');
    expect(adapter.lastRequest.data, {'courseId': 'c1', 'source': 'admin'});
  });

  test('pausing and resuming send the route\'s own two words', () async {
    final enrollment =
        (((fixture('staff/student.json')! as Map<String, dynamic>)['enrollments']! as List).first
            as Map<String, dynamic>)['enrollment'];
    adapter
      ..enqueueJson(enrollment)
      ..enqueueJson(enrollment);

    await api.setEnrollmentStatus('e1', paused: true);
    expect(adapter.lastRequest.method, 'PATCH');
    expect(adapter.lastRequest.path, '/students/enrollments/e1');
    expect(adapter.lastRequest.data, {'status': 'paused'});

    await api.setEnrollmentStatus('e1', paused: false);
    expect(adapter.lastRequest.data, {'status': 'active'});
  });

  test('removing an enrolment is a delete with no body', () async {
    adapter.enqueue((_) async => FakeAdapter.noContent());

    await api.removeEnrollment('e1');

    expect(adapter.lastRequest.method, 'DELETE');
    expect(adapter.lastRequest.path, '/students/enrollments/e1');
    expect(adapter.lastRequest.data, isNull);
  });

  test('suspending sends the reason only when there is one', () async {
    final student = (fixture('staff/student.json')! as Map<String, dynamic>)['student'];
    adapter
      ..enqueueJson(student)
      ..enqueueJson(student);

    await api.setSuspended('s1', suspended: true, reason: 'Repeated plagiarism.');
    expect(adapter.lastRequest.path, '/students/s1/suspend');
    expect(adapter.lastRequest.data, {'suspended': true, 'reason': 'Repeated plagiarism.'});

    await api.setSuspended('s1', suspended: false);
    expect(adapter.lastRequest.data, {'suspended': false});
  });
}
