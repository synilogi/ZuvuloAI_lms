import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_calendar/staff_calendar.dart';

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

/// A Wednesday, so the week runs 28 Sep – 4 Oct.
final _now = DateTime.utc(2026, 9, 30, 8);

Map<String, dynamic> _event() =>
    (fixture('staff/calendar-reminder.json')! as Map<String, dynamic>)['event']!
        as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({Object? write, int writeStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(write ?? _event(), status: writeStatus);
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path == '/quizzes') {
        return FakeAdapter.jsonResponse(fixture('staff/quizzes.json'));
      }
      if (options.path.startsWith('/calendar/')) {
        return FakeAdapter.jsonResponse(fixture('staff/calendar-reminder.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/calendar-month.json'));
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
    container.listen(calendarActionProvider, (_, _) {});
    return container;
  }

  group('the view', () {
    test('opens on today, in the week it falls in', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});

      await c.read(calendarRangeProvider.future);

      expect(c.read(calendarViewProvider).day, DateTime.utc(2026, 9, 30));
      expect(adapter.lastRequest.queryParameters, {'from': '2026-09-28', 'to': '2026-10-04'});
    });

    test('moving a week asks for the next range', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});
      c.read(calendarViewProvider.notifier).moveWeeks(1);

      await c.read(calendarRangeProvider.future);

      expect(adapter.lastRequest.queryParameters, {'from': '2026-10-05', 'to': '2026-10-11'});
      expect(c.read(calendarViewProvider).day, DateTime.utc(2026, 10, 7));
    });

    test('a month view asks for the whole grid', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});
      c.read(calendarViewProvider.notifier).showWholeMonth(whole: true);

      await c.read(calendarRangeProvider.future);

      // September 2026 opens on a Tuesday, so the grid starts on 31 August.
      expect(adapter.lastRequest.queryParameters['from'], '2026-08-31');
    });

    test('today brings it back, whatever week it was on', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});
      c.read(calendarViewProvider.notifier).moveWeeks(4);
      expect(c.read(calendarViewProvider).day, isNot(DateTime.utc(2026, 9, 30)));

      c.read(calendarViewProvider.notifier).showToday();

      expect(c.read(calendarViewProvider).day, DateTime.utc(2026, 9, 30));
    });

    test('picking a day keeps the range, because it is the same week', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});
      await c.read(calendarRangeProvider.future);
      final reads = adapter.requests.length;

      c.read(calendarViewProvider.notifier).showDay(DateTime.utc(2026, 10, 2));
      await c.read(calendarRangeProvider.future);

      expect(
        adapter.requests.length,
        greaterThan(reads),
        reason: 'the provider re-reads because the day is part of the view',
      );
      expect(adapter.lastRequest.queryParameters, {'from': '2026-09-28', 'to': '2026-10-04'});
    });

    test('a type narrows the read, and "everything" clears it', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});
      c.read(calendarViewProvider.notifier).toggleType(CalendarEventType.reminder);
      await c.read(calendarRangeProvider.future);
      expect(adapter.lastRequest.queryParameters['types'], const ['reminder']);

      c.read(calendarViewProvider.notifier).showEveryType();
      await c.read(calendarRangeProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('types'), isFalse);
    });

    test('a course and an instructor narrow it together', () async {
      answering();
      final c = container();
      c.listen(calendarRangeProvider, (_, _) {});
      c.read(calendarViewProvider.notifier)
        ..inCourse('c1')
        ..byInstructor('i1');

      await c.read(calendarRangeProvider.future);

      expect(adapter.lastRequest.queryParameters['courseId'], 'c1');
      expect(adapter.lastRequest.queryParameters['instructorId'], 'i1');
    });
  });

  group('the form', () {
    test('a new event opens an hour ahead, on the hour', () async {
      answering();
      final c = container();
      c.listen(calendarFormProvider(null), (_, _) {});

      final form = c.read(calendarFormProvider(null));

      expect(form.type, CalendarEventType.reminder);
      expect(form.startsAt!.isAfter(_now), isTrue);
      expect(c.read(calendarFormProvider(null).notifier).dirty, isFalse);
    });

    test('an edit starts from the event as the academy has it', () async {
      answering();
      final c = container();
      c.listen(calendarFormProvider('e1'), (_, _) {});
      await c.read(calendarEventProvider('e1').future);

      final form = c.read(calendarFormProvider('e1'));

      expect(form.title, contains('chart pack'));
      expect(form.durationMin, 30);
      expect(form.notifyMin, 60);
      expect(form.audience, ReminderAudience.me);
      expect(c.read(calendarFormProvider('e1').notifier).dirty, isFalse);
    });

    test('typing marks it unsaved, and saving clears the mark', () async {
      answering();
      final c = container();
      c.listen(calendarFormProvider(null), (_, _) {});
      final controller = c.read(calendarFormProvider(null).notifier);

      controller.titled('Prepare the chart pack');
      expect(controller.dirty, isTrue);

      controller.saved();
      expect(controller.dirty, isFalse);
    });

    test('changing the type keeps what was typed', () async {
      answering();
      final c = container();
      c.listen(calendarFormProvider(null), (_, _) {});
      final controller = c.read(calendarFormProvider(null).notifier)
        ..titled('Chapter two opens')
        ..ofType(CalendarEventType.milestone)
        ..marking(MilestoneKind.chapterRelease);

      final form = c.read(calendarFormProvider(null));
      expect(form.title, 'Chapter two opens');
      expect(form.type, CalendarEventType.milestone);
      expect(form.milestone, MilestoneKind.chapterRelease);
      expect(controller.dirty, isTrue);
    });
  });

  group('the actions', () {
    CalendarEventForm ready() => CalendarEventForm(
      title: 'Prepare the chart pack',
      startsAt: _now.add(const Duration(days: 1)),
      durationMin: 30,
    );

    test('adding one answers with the event and re-reads the range', () async {
      answering();
      final c = container();
      var reads = 0;
      c.listen(calendarRangeProvider, (_, _) {
        reads++;
      });
      await c.read(calendarRangeProvider.future);

      final id = await c.read(calendarActionProvider.notifier).create(ready());
      await c.read(calendarRangeProvider.future);

      expect(id, isNotNull);
      expect(c.read(calendarActionProvider).savedId, id);
      expect(reads, greaterThan(1));
    });

    test('a refused write keeps the academy\'s words on each field', () async {
      answering(
        write: const {
          'message': 'Check the event before saving.',
          'issues': [
            {'field': 'title', 'message': 'Give the event a title of at least 3 characters.'},
            {'field': 'startsAt', 'message': 'That time has already passed. Choose a later time.'},
          ],
        },
        writeStatus: 409,
      );
      final c = container();

      final id = await c.read(calendarActionProvider.notifier).create(ready());
      final state = c.read(calendarActionProvider);

      expect(id, isNull);
      expect(state.issues, hasLength(2));
      expect(state.messageFor('title'), contains('3 characters'));
      expect(state.messageFor('startsAt'), contains('already passed'));
      expect(state.messageFor('duration'), isNull);
      expect(state.failure, isNull);
    });

    test('a refusal with no field is kept as the academy sent it', () async {
      answering(write: const {'message': 'Course not found.'}, writeStatus: 404);
      final c = container();

      expect(await c.read(calendarActionProvider.notifier).create(ready()), isNull);
      expect(c.read(calendarActionProvider).issues, isEmpty);
      expect(c.read(calendarActionProvider).failure, isA<NotFoundFailure>());
    });

    test('ticking one off sends which way, and re-reads it', () async {
      answering(write: {..._event(), 'done': true});
      final c = container();
      var reads = 0;
      c.listen(calendarEventProvider('e1'), (_, _) {
        reads++;
      });
      await c.read(calendarEventProvider('e1').future);

      final ok = await c.read(calendarActionProvider.notifier).setDone('e1', done: true);
      await c.read(calendarEventProvider('e1').future);

      expect(ok, isTrue);
      expect((adapter.requests.where((r) => r.method == 'POST').last.data! as Map)['done'], isTrue);
      expect(reads, greaterThan(1));
    });

    test('removing one re-reads the range', () async {
      adapter.handler = (options) async => options.method == 'DELETE'
          ? FakeAdapter.noContent()
          : FakeAdapter.jsonResponse(fixture('staff/calendar-month.json'));
      final c = container();
      var reads = 0;
      c.listen(calendarRangeProvider, (_, _) {
        reads++;
      });
      await c.read(calendarRangeProvider.future);

      final ok = await c.read(calendarActionProvider.notifier).remove('e1');
      await c.read(calendarRangeProvider.future);

      expect(ok, isTrue);
      expect(c.read(calendarActionProvider).removed, isTrue);
      expect(reads, greaterThan(1));
    });

    test('a second action is ignored while the first is in flight', () async {
      answering();
      final c = container();
      final controller = c.read(calendarActionProvider.notifier);

      final first = controller.create(ready());
      final second = controller.setDone('e1', done: true);

      expect(await second, isFalse);
      expect(await first, isNotNull);
      expect(adapter.requests.where((r) => r.method != 'GET'), hasLength(1));
    });
  });
}
