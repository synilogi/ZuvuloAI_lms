import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_students/staff_students.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Answers by path, so a test never depends on the order the providers settle in.
  void answering({Object? action, int actionStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(
          action ?? (fixture('staff/student.json')! as Map<String, dynamic>)['student'],
          status: actionStatus,
        );
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path.endsWith('/progress')) {
        return FakeAdapter.jsonResponse(fixture('staff/student-progress.json'));
      }
      if (options.path.endsWith('/activity')) {
        return FakeAdapter.jsonResponse(fixture('staff/student-activity.json'));
      }
      if (options.path.startsWith('/students/')) {
        return FakeAdapter.jsonResponse(fixture('staff/student.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/students.json'));
    };
  }

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _admin(),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container.listen(studentActionProvider, (_, _) {});
    return container;
  }

  group('the roster', () {
    test('opens on everyone, sorted the route\'s own way', () async {
      answering();
      final c = container();
      c.listen(rosterProvider, (_, _) {});

      await c.read(rosterProvider.future);

      expect(
        adapter.lastRequest.queryParameters,
        {'page': 1, 'pageSize': 20},
        reason: '"all" and last-active-first are the app\'s words for sending nothing',
      );
    });

    test('a status tab and a sort travel as the route names them', () async {
      answering();
      final c = container();
      c.listen(rosterProvider, (_, _) {});
      c.read(rosterFilterProvider.notifier)
        ..showStatus('at-risk')
        ..sortBy('progress');

      await c.read(rosterProvider.future);

      expect(adapter.lastRequest.queryParameters['status'], 'at-risk');
      expect(adapter.lastRequest.queryParameters['sort'], 'progress');
    });

    test('a new filter starts at the first page again', () async {
      answering();
      final c = container();
      c.listen(rosterProvider, (_, _) {});
      c.read(rosterFilterProvider.notifier).showPage(3);
      await c.read(rosterProvider.future);
      expect(adapter.lastRequest.queryParameters['page'], 3);

      c.read(rosterFilterProvider.notifier).searchFor('ananya');
      await c.read(rosterProvider.future);

      expect(adapter.lastRequest.queryParameters['page'], 1);
      expect(adapter.lastRequest.queryParameters['search'], 'ananya');
    });

    test('clearing the search drops it rather than sending nothing', () async {
      answering();
      final c = container();
      c.listen(rosterProvider, (_, _) {});
      c.read(rosterFilterProvider.notifier).searchFor('  ananya  ');
      await c.read(rosterProvider.future);
      expect(adapter.lastRequest.queryParameters['search'], 'ananya');

      c.read(rosterFilterProvider.notifier).searchFor('  ');
      await c.read(rosterProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('search'), isFalse);
    });
  });

  group('picking learners', () {
    test('holds the ones picked, and lets go of one picked twice', () async {
      answering();
      final c = container();
      c.listen(rosterSelectionProvider, (_, _) {});
      final selection = c.read(rosterSelectionProvider.notifier);

      selection
        ..toggle('s1')
        ..toggle('s2');
      expect(c.read(rosterSelectionProvider), {'s1', 's2'});
      expect(selection.holds('s1'), isTrue);

      selection.toggle('s1');
      expect(c.read(rosterSelectionProvider), {'s2'});

      selection.clear();
      expect(c.read(rosterSelectionProvider), isEmpty);
    });
  });

  group('writing a message', () {
    test('is not ready until it has a subject, enough body and a channel', () {
      const empty = MessageDraft();
      expect(empty.isReady, isFalse);

      const noBody = MessageDraft(subject: 'Next week');
      expect(noBody.hasSubject, isTrue);
      expect(noBody.isReady, isFalse);

      const tooShort = MessageDraft(subject: 'Next week', body: 'Too short');
      expect(tooShort.hasBody, isFalse, reason: 'the route asks for ten characters');

      const ready = MessageDraft(subject: 'Next week', body: 'The live class moves to Thursday.');
      expect(ready.isReady, isTrue);

      const noChannel = MessageDraft(
        subject: 'Next week',
        body: 'The live class moves to Thursday.',
        channels: {},
      );
      expect(noChannel.isReady, isFalse, reason: 'the route refuses a message with no channel');
    });

    test('a subject longer than the route allows is not ready either', () {
      final long = MessageDraft(
        subject: 'x' * (MessageDraft.maxSubject + 1),
        body: 'The live class moves to Thursday.',
      );
      expect(long.hasSubject, isFalse);
    });

    test('channels toggle, and the app opens on the in-app one', () async {
      answering();
      final c = container();
      c.listen(messageDraftProvider, (_, _) {});
      expect(c.read(messageDraftProvider).channels, {'app'});

      c.read(messageDraftProvider.notifier).toggleChannel('email');
      expect(c.read(messageDraftProvider).channels, {'app', 'email'});

      c.read(messageDraftProvider.notifier).toggleChannel('app');
      expect(c.read(messageDraftProvider).channels, {'email'});
    });

    test('the academy\'s count is what comes back, not the number asked for', () async {
      adapter.handler = (options) async => options.method == 'POST'
          ? FakeAdapter.jsonResponse(const {'sent': 1})
          : FakeAdapter.jsonResponse(fixture('staff/students.json'));
      final c = container();

      final ok = await c
          .read(studentActionProvider.notifier)
          .message(
            studentIds: const ['s1', 's2', 's3'],
            subject: 'Next week',
            body: 'The live class moves to Thursday.',
            channels: const {'app'},
          );

      expect(ok, isTrue);
      expect(
        c.read(studentActionProvider).sent,
        1,
        reason: 'two of the three were out of scope and the route dropped them',
      );
    });

    test('a refused message is kept in the academy\'s own words', () async {
      adapter.handler = (options) async => options.method == 'POST'
          ? FakeAdapter.jsonResponse(const {
              'message': 'You may not message learners.',
              'code': 'PERMISSION_DENIED',
            }, status: 403)
          : FakeAdapter.jsonResponse(fixture('staff/students.json'));
      final c = container();

      final ok = await c
          .read(studentActionProvider.notifier)
          .message(
            studentIds: const ['s1'],
            subject: 'Next week',
            body: 'The live class moves to Thursday.',
            channels: const {'app'},
          );

      expect(ok, isFalse);
      expect(c.read(studentActionProvider).failure, isA<PermissionFailure>());
      expect(c.read(studentActionProvider).sent, isNull);
    });
  });

  group('the actions on a learner', () {
    test('enrolling re-reads the roster, the profile and everything under it', () async {
      answering();
      final c = container();
      var rosterReads = 0;
      var profileReads = 0;
      c.listen(rosterProvider, (_, _) {
        rosterReads++;
      });
      c.listen(studentProfileProvider('s1'), (_, _) {
        profileReads++;
      });
      await c.read(rosterProvider.future);
      await c.read(studentProfileProvider('s1').future);

      final ok = await c.read(studentActionProvider.notifier).enroll('s1', courseId: 'c1');
      await c.read(rosterProvider.future);

      expect(ok, isTrue);
      expect(c.read(studentActionProvider).done, isTrue);
      expect(rosterReads, greaterThan(1));
      expect(profileReads, greaterThan(1));
    });

    test('pausing and resuming both go through, and say which way', () async {
      answering(
        action:
            (((fixture('staff/student.json')! as Map<String, dynamic>)['enrollments']! as List)
                    .first
                as Map<String, dynamic>)['enrollment'],
      );
      final c = container();

      expect(await c.read(studentActionProvider.notifier).pause('s1', 'e1', paused: true), isTrue);
      expect((adapter.lastRequest.data! as Map)['status'], 'paused');
      c.read(studentActionProvider.notifier).clearAnswer();

      expect(await c.read(studentActionProvider.notifier).pause('s1', 'e1', paused: false), isTrue);
      expect((adapter.lastRequest.data! as Map)['status'], 'active');
    });

    test('removing an enrolment goes through as a delete', () async {
      adapter.handler = (options) async => options.method == 'DELETE'
          ? FakeAdapter.noContent()
          : FakeAdapter.jsonResponse(fixture('staff/students.json'));
      final c = container();

      expect(await c.read(studentActionProvider.notifier).removeEnrollment('s1', 'e1'), isTrue);
      expect(adapter.lastRequest.method, 'DELETE');
    });

    test('suspending carries the reason, and restoring carries none', () async {
      answering();
      final c = container();

      await c
          .read(studentActionProvider.notifier)
          .setSuspended('s1', suspended: true, reason: 'Repeated plagiarism.');
      expect((adapter.lastRequest.data! as Map)['reason'], 'Repeated plagiarism.');
      c.read(studentActionProvider.notifier).clearAnswer();

      await c.read(studentActionProvider.notifier).setSuspended('s1', suspended: false);
      expect((adapter.lastRequest.data! as Map).containsKey('reason'), isFalse);
    });

    test('a refusal is kept as the academy sent it', () async {
      answering(
        action: const {'message': 'Only an admin may suspend a learner.'},
        actionStatus: 403,
      );
      final c = container();

      final ok = await c.read(studentActionProvider.notifier).setSuspended('s1', suspended: true);

      expect(ok, isFalse);
      expect(c.read(studentActionProvider).failure, isA<ForbiddenFailure>());
      expect(c.read(studentActionProvider).failure!.message, contains('Only an admin'));
      expect(c.read(studentActionProvider).done, isFalse);
    });

    test('a second action is ignored while the first is in flight', () async {
      answering();
      final c = container();
      final controller = c.read(studentActionProvider.notifier);

      final first = controller.setSuspended('s1', suspended: true);
      final second = controller.enroll('s1', courseId: 'c1');

      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(adapter.requests.where((r) => r.method != 'GET'), hasLength(1));
    });
  });

  group('the activity filter', () {
    test('"all" is the app\'s word for no kind at all', () async {
      answering();
      final c = container();
      c.listen(studentActivityProvider('s1'), (_, _) {});
      await c.read(studentActivityProvider('s1').future);
      expect(adapter.lastRequest.queryParameters, isEmpty);

      c.read(activityFilterProvider.notifier).ofKind('all');
      await c.read(studentActivityProvider('s1').future);

      expect(adapter.lastRequest.queryParameters.containsKey('kind'), isFalse);
    });

    test('a kind and a course narrow it together', () async {
      answering();
      final c = container();
      c.listen(studentActivityProvider('s1'), (_, _) {});
      c.read(activityFilterProvider.notifier)
        ..ofKind('lesson-completed')
        ..inCourse('c1');

      await c.read(studentActivityProvider('s1').future);

      expect(adapter.lastRequest.queryParameters, {'kind': 'lesson-completed', 'courseId': 'c1'});
    });
  });
}
