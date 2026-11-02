import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/platform/clock.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_live/staff_live.dart';

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

/// A fixed clock, so a phase in a test never depends on when the test runs.
final _now = DateTime.utc(2026, 9, 30, 12);

Map<String, dynamic> _liveClass() =>
    (fixture('staff/live-class.json')! as Map<String, dynamic>)['liveClass']!
        as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({Object? write, int writeStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(write ?? _liveClass(), status: writeStatus);
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(fixture('staff/instructors.json'));
      }
      if (options.path.startsWith('/live/')) {
        return FakeAdapter.jsonResponse(fixture('staff/live-class.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/live-schedule.json'));
    };
  }

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _admin(),
        clock: () => _now,
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container.listen(liveActionProvider, (_, _) {});
    return container;
  }

  group('the schedule', () {
    test('opens on what is coming up', () async {
      answering();
      final c = container();
      c.listen(staffLiveScheduleProvider, (_, _) {});

      await c.read(staffLiveScheduleProvider.future);

      expect(adapter.lastRequest.queryParameters, {'view': 'upcoming', 'page': 1, 'pageSize': 20});
    });

    test('a view and a course travel as the route names them', () async {
      answering();
      final c = container();
      c.listen(staffLiveScheduleProvider, (_, _) {});
      c.read(liveFilterProvider.notifier)
        ..show('cancelled')
        ..inCourse('c1');

      await c.read(staffLiveScheduleProvider.future);

      expect(adapter.lastRequest.queryParameters['view'], 'cancelled');
      expect(adapter.lastRequest.queryParameters['courseId'], 'c1');
    });

    test('a new filter starts at the first page again', () async {
      answering();
      final c = container();
      c.listen(staffLiveScheduleProvider, (_, _) {});
      c.read(liveFilterProvider.notifier).showPage(2);
      await c.read(staffLiveScheduleProvider.future);
      expect(adapter.lastRequest.queryParameters['page'], 2);

      c.read(liveFilterProvider.notifier).show('history');
      await c.read(staffLiveScheduleProvider.future);

      expect(adapter.lastRequest.queryParameters['page'], 1);
    });
  });

  group('the form', () {
    test('a new class opens an hour ahead, on the device\'s own clock', () async {
      answering();
      final c = container();
      c.listen(liveFormProvider(null), (_, _) {});

      final form = c.read(liveFormProvider(null));

      expect(form.startsAt!.isAfter(_now), isTrue);
      expect(form.startsAt!.difference(_now).inMinutes, lessThanOrEqualTo(60));
      expect(c.read(liveFormProvider(null).notifier).dirty, isFalse);
    });

    test('an edit starts from the class as the academy has it', () async {
      answering();
      final c = container();
      c.listen(liveFormProvider('l1'), (_, _) {});
      await c.read(staffLiveClassProvider('l1').future);

      final form = c.read(liveFormProvider('l1'));

      expect(form.title, 'Reading dignities in real charts');
      expect(form.capacity, 40);
      expect(form.agenda, hasLength(3));
      expect(form.reminders, [1440, 60]);
      expect(c.read(liveFormProvider('l1').notifier).dirty, isFalse);
    });

    test('typing marks it unsaved', () async {
      answering();
      final c = container();
      c.listen(liveFormProvider(null), (_, _) {});
      final controller = c.read(liveFormProvider(null).notifier);
      expect(controller.dirty, isFalse);

      controller.titled('Reading dignities');

      expect(controller.dirty, isTrue);
      expect(c.read(liveFormProvider(null)).title, 'Reading dignities');
    });

    test('an agenda item can be added, changed and taken out again', () async {
      answering();
      final c = container();
      c.listen(liveFormProvider(null), (_, _) {});
      final controller = c.read(liveFormProvider(null).notifier)..addAgendaItem();
      expect(c.read(liveFormProvider(null)).agenda, hasLength(1));

      controller.editAgendaItem(0, title: 'Recap', minutes: 20);
      expect(c.read(liveFormProvider(null)).agenda.single.title, 'Recap');
      expect(c.read(liveFormProvider(null)).agendaMinutes, 20);

      controller.removeAgendaItem(0);
      expect(c.read(liveFormProvider(null)).agenda, isEmpty);
    });

    test('a reminder offset toggles, and the route\'s own limit is respected', () async {
      answering();
      final c = container();
      c.listen(liveFormProvider(null), (_, _) {});
      final controller = c.read(liveFormProvider(null).notifier);

      controller.toggleReminder(60);
      expect(c.read(liveFormProvider(null)).reminders, [60]);
      controller.toggleReminder(1440);
      expect(c.read(liveFormProvider(null)).reminders, [
        1440,
        60,
      ], reason: 'the furthest ahead reads first');
      controller.toggleReminder(60);
      expect(c.read(liveFormProvider(null)).reminders, [1440]);

      // Ten is the most the route's schema takes, so an eleventh is not offered.
      for (final minutes in [5, 10, 15, 30, 45, 90, 120, 180, 240]) {
        controller.toggleReminder(minutes);
      }
      expect(c.read(liveFormProvider(null)).reminders, hasLength(10));
      controller.toggleReminder(300);
      expect(c.read(liveFormProvider(null)).reminders, hasLength(10));
    });

    test('saving clears the unsaved mark', () async {
      answering();
      final c = container();
      c.listen(liveFormProvider(null), (_, _) {});
      final controller = c.read(liveFormProvider(null).notifier)..titled('Reading dignities');

      controller.saved();

      expect(controller.dirty, isFalse);
    });
  });

  group('the actions', () {
    LiveClassForm ready() => LiveClassForm(
      courseId: 'c1',
      title: 'Reading dignities',
      instructorId: 'i1',
      startsAt: _now.add(const Duration(hours: 2)),
      durationMin: 60,
      meetingLink: 'https://meet.example.com/x',
    );

    test('scheduling answers with the class the academy made, and re-reads the schedule', () async {
      answering();
      final c = container();
      var reads = 0;
      c.listen(staffLiveScheduleProvider, (_, _) {
        reads++;
      });
      await c.read(staffLiveScheduleProvider.future);

      final id = await c.read(liveActionProvider.notifier).create(ready());
      await c.read(staffLiveScheduleProvider.future);

      expect(id, isNotNull);
      expect(c.read(liveActionProvider).savedId, id);
      expect(reads, greaterThan(1));
    });

    test('a refused write keeps the academy\'s words against each field', () async {
      answering(
        write: const {
          'message': 'Check the class details before scheduling.',
          'issues': [
            {'field': 'startsAt', 'message': 'The start time has already passed.'},
            {'field': 'meeting', 'message': 'Paste the full meeting link, starting with https://'},
          ],
        },
        writeStatus: 409,
      );
      final c = container();

      final id = await c.read(liveActionProvider.notifier).create(ready());
      final state = c.read(liveActionProvider);

      expect(id, isNull);
      expect(state.issues, hasLength(2));
      expect(state.messageFor('startsAt'), contains('already passed'));
      expect(state.messageFor('meeting'), contains('https://'));
      expect(state.messageFor('title'), isNull);
      expect(state.failure, isNull, reason: 'the fields are the explanation');
    });

    test('an edit the academy refuses outright is kept in its own words', () async {
      answering(
        write: const {'message': 'This class has already started and can no longer be edited.'},
        writeStatus: 409,
      );
      final c = container();

      final ok = await c.read(liveActionProvider.notifier).save('l1', ready());

      expect(ok, isFalse);
      expect(c.read(liveActionProvider).issues, isEmpty);
      expect(c.read(liveActionProvider).failure!.message, contains('already started'));
    });

    test('a month\'s allowance used up is kept as an entitlement refusal', () async {
      answering(
        write: const {
          'message': 'Your plan allows 8 live classes a month.',
          'code': 'LIMIT_REACHED',
        },
        writeStatus: 403,
      );
      final c = container();

      expect(await c.read(liveActionProvider.notifier).create(ready()), isNull);
      expect(
        c.read(liveActionProvider).failure,
        isA<EntitlementFailure>().having(
          (f) => f.problem,
          'problem',
          EntitlementProblem.limitReached,
        ),
      );
    });

    test('cancelling carries the reason and re-reads the class', () async {
      answering();
      final c = container();
      var reads = 0;
      c.listen(staffLiveClassProvider('l1'), (_, _) {
        reads++;
      });
      await c.read(staffLiveClassProvider('l1').future);

      final ok = await c
          .read(liveActionProvider.notifier)
          .cancel('l1', reason: 'The instructor is unwell.');
      await c.read(staffLiveClassProvider('l1').future);

      expect(ok, isTrue);
      // The re-read is the last request now, so the cancel is found by its own verb.
      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, '/live/l1/cancel');
      expect((sent.data! as Map)['reason'], 'The instructor is unwell.');
      expect(reads, greaterThan(1));
    });

    test('a reminder reports the academy\'s count', () async {
      answering(write: const {'sent': 4});
      final c = container();

      expect(await c.read(liveActionProvider.notifier).remind('l1'), isTrue);
      expect(c.read(liveActionProvider).sent, 4);
    });

    test('a second action is ignored while the first is in flight', () async {
      answering();
      final c = container();
      final controller = c.read(liveActionProvider.notifier);

      final first = controller.create(ready());
      final second = controller.cancel('l1', reason: 'Called off.');

      expect(await second, isFalse);
      expect(await first, isNotNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), hasLength(1));
    });
  });

  group('the ticking clock', () {
    test('starts from the device clock the app was given', () async {
      answering();
      final c = container();

      expect(c.read(clockProvider)(), _now);
    });
  });
}
