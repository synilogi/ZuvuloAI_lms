import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_review/staff_review.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _staff() => UserProfile(
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
  void answering({String detail = 'submission', Object? review, int reviewStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method == 'POST') {
        return FakeAdapter.jsonResponse(
          review ?? (fixture('staff/$detail.json')! as Map<String, dynamic>)['submission'],
          status: reviewStatus,
        );
      }
      if (options.path == '/assignments/review') {
        return FakeAdapter.jsonResponse(fixture('staff/review-queue.json'));
      }
      if (options.path == '/assignments') {
        return FakeAdapter.jsonResponse(fixture('staff/assignments.json'));
      }
      if (options.path.startsWith('/assignments/submissions/')) {
        return FakeAdapter.jsonResponse(fixture('staff/$detail.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/submissions.json'));
    };
  }

  ProviderContainer container() {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: _staff(),
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the queue', () {
    test('opens on what is waiting, oldest first', () async {
      answering();
      final c = container();
      c.listen(submissionsProvider, (_, _) {});

      await c.read(submissionsProvider.future);

      expect(adapter.lastRequest.queryParameters, {
        'filter': 'to-review',
        'sort': 'oldest',
        'page': 1,
        'pageSize': 20,
      });
    });

    test('"all" is the app\'s word for no filter, so none is sent', () async {
      answering();
      final c = container();
      c.listen(submissionsProvider, (_, _) {});
      c.read(submissionFilterProvider.notifier).show('all');

      await c.read(submissionsProvider.future);

      expect(adapter.lastRequest.queryParameters.containsKey('filter'), isFalse);
    });

    test('a new filter starts at the first page again', () async {
      answering();
      final c = container();
      c.listen(submissionsProvider, (_, _) {});
      c.read(submissionFilterProvider.notifier).showPage(3);
      await c.read(submissionsProvider.future);
      expect(adapter.lastRequest.queryParameters['page'], 3);

      c.read(submissionFilterProvider.notifier).show('graded');
      await c.read(submissionsProvider.future);

      expect(adapter.lastRequest.queryParameters['page'], 1);
      expect(adapter.lastRequest.queryParameters['filter'], 'graded');
    });

    test('an assignment chosen in the picker uses its own route', () async {
      answering();
      final c = container();
      c.listen(submissionsProvider, (_, _) {});
      c.read(submissionFilterProvider.notifier).forAssignment('a1');

      await c.read(submissionsProvider.future);

      expect(adapter.lastRequest.path, '/assignments/a1/submissions');
    });

    test('an assignment read the academy refuses leaves the picker empty', () async {
      adapter.handler = (options) async => options.path == '/assignments'
          ? FakeAdapter.jsonResponse(const {'message': 'No.'}, status: 403)
          : FakeAdapter.jsonResponse(fixture('staff/submissions.json'));
      final c = container();

      expect(await c.read(staffAssignmentsProvider.future), isEmpty);
      expect((await c.read(submissionsProvider.future)).rows, isNotEmpty);
    });
  });

  group('writing a review', () {
    test('it opens on whatever was already saved', () async {
      answering();
      final c = container();
      final graded = (fixture('staff/submissions.json')! as Map<String, dynamic>)['rows']! as List;
      final row = graded.firstWhere((r) {
        final review = ((r as Map)['submission']! as Map)['review']! as Map;
        return review['status'] == 'graded';
      });
      adapter.handler = (options) async => options.path.startsWith('/assignments/submissions/')
          ? FakeAdapter.jsonResponse({
              ...fixture('staff/submission.json')! as Map<String, dynamic>,
              'submission': (row as Map)['submission'],
            })
          : FakeAdapter.jsonResponse(fixture('staff/submissions.json'));

      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);

      final draft = c.read(reviewProvider('s1'));
      expect(draft.feedback, isNotEmpty, reason: 'the reviewer sees what they wrote before');
      expect(draft.dirty, isFalse);
    });

    test('nothing is dirty until something is typed', () async {
      answering();
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);
      expect(c.read(reviewProvider('s1')).dirty, isFalse);

      c.read(reviewProvider('s1').notifier).writeFeedback('Well argued.');

      expect(c.read(reviewProvider('s1')).dirty, isTrue);
    });

    test('a grade the academy accepts clears the draft and re-reads the queue', () async {
      answering();
      final c = container();
      var queueReads = 0;
      c.listen(reviewQueueProvider, (_, _) {
        queueReads++;
      });
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(reviewQueueProvider.future);
      await c.read(submissionProvider('s1').future);
      final controller = c.read(reviewProvider('s1').notifier)
        ..scorePoints(72)
        ..writeFeedback('Clear and well argued.');

      final ok = await controller.grade();
      await c.read(reviewQueueProvider.future);

      expect(ok, isTrue);
      final draft = c.read(reviewProvider('s1'));
      expect(draft.dirty, isFalse, reason: 'there is nothing unsaved to warn about any more');
      expect(draft.issues, isEmpty);
      expect(draft.busy, isFalse);
      expect(queueReads, greaterThan(1), reason: 'the queue is one shorter');
    });

    test(
      'a refused decision keeps the academy\'s words against the field they belong to',
      () async {
        answering(review: fixture('errors/review-refused.json'), reviewStatus: 409);
        final c = container();
        c.listen(reviewProvider('s1'), (_, _) {});
        await c.read(submissionProvider('s1').future);

        final ok = await c.read(reviewProvider('s1').notifier).grade();

        expect(ok, isFalse);
        final draft = c.read(reviewProvider('s1'));
        expect(draft.busy, isFalse);
        expect(draft.issues, hasLength(2));
        expect(draft.messageFor('points'), contains('0 to 100'));
        expect(draft.messageFor('feedback'), contains('line of feedback'));
        expect(draft.failure, isNull, reason: 'the fields are the explanation');
      },
    );

    test('a refusal that is not about a field is kept as one', () async {
      answering(
        review: const {'message': 'You may not grade this course.', 'code': 'PERMISSION_DENIED'},
        reviewStatus: 403,
      );
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);

      final ok = await c.read(reviewProvider('s1').notifier).grade();

      expect(ok, isFalse);
      expect(c.read(reviewProvider('s1')).issues, isEmpty);
      expect(c.read(reviewProvider('s1')).failure, isA<PermissionFailure>());
    });

    test('typing again clears what the academy said about the old attempt', () async {
      answering(review: fixture('errors/review-refused.json'), reviewStatus: 409);
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);
      await c.read(reviewProvider('s1').notifier).grade();
      expect(c.read(reviewProvider('s1')).issues, isNotEmpty);

      c.read(reviewProvider('s1').notifier).writeFeedback('A fuller line of feedback.');

      expect(c.read(reviewProvider('s1')).issues, isEmpty);
    });

    test('a second decision is ignored while the first is in flight', () async {
      answering();
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);
      final controller = c.read(reviewProvider('s1').notifier);

      final first = controller.grade();
      final second = controller.saveDraft();

      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
    });

    test('the estimate is the app\'s arithmetic and says which way the pass mark lies', () async {
      answering(detail: 'submission-rubric');
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      final detail = await c.read(submissionProvider('s1').future);
      final controller = c.read(reviewProvider('s1').notifier)
        ..score('lagna', 18)
        ..score('moon', 15)
        ..score('nakshatra', 8);

      final estimate = controller.estimate(detail);

      expect(estimate.raw, 41);
      expect(estimate.max, 50);
      expect(estimate.score, greaterThan(detail.assignment.passMark));
    });

    test('what the server would refuse is known before it is asked', () async {
      answering(detail: 'submission-rubric');
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      final detail = await c.read(submissionProvider('s1').future);
      final controller = c.read(reviewProvider('s1').notifier);

      expect(controller.problemsWith(detail, ReviewStatus.graded), isNotEmpty);

      controller
        ..score('lagna', 18)
        ..score('moon', 15)
        ..score('nakshatra', 8)
        ..writeFeedback('Clear and well argued.');

      expect(controller.problemsWith(detail, ReviewStatus.graded), isEmpty);
    });

    test('a draft is saved with no score at all, and the academy keeps it as in-review', () async {
      answering();
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);

      final ok = await c.read(reviewProvider('s1').notifier).saveDraft();

      expect(ok, isTrue);
      expect((adapter.lastRequest.data! as Map)['decision'], 'draft');
    });

    test('a private note is sent only when there is one', () async {
      answering();
      final c = container();
      c.listen(reviewProvider('s1'), (_, _) {});
      await c.read(submissionProvider('s1').future);

      await c.read(reviewProvider('s1').notifier).saveDraft();
      expect((adapter.lastRequest.data! as Map).containsKey('privateNote'), isFalse);

      c.read(reviewProvider('s1').notifier).writePrivateNote('  Stronger than the first go.  ');
      await c.read(reviewProvider('s1').notifier).saveDraft();

      expect((adapter.lastRequest.data! as Map)['privateNote'], contains('Stronger'));
    });
  });

  group('reminding who is missing', () {
    test('the academy decides who, and says how many it reached', () async {
      adapter.handler = (options) async => options.method == 'POST'
          ? FakeAdapter.jsonResponse(const {'sent': 5})
          : FakeAdapter.jsonResponse(fixture('staff/submissions.json'));
      final c = container();
      c.listen(remindProvider, (_, _) {});

      final ok = await c.read(remindProvider.notifier).remind('a1');

      expect(ok, isTrue);
      expect(c.read(remindProvider).sent, 5);
      expect((adapter.lastRequest.data! as Map)['studentIds'], isEmpty);
    });

    test('a refusal is kept in the academy\'s own words', () async {
      adapter.handler = (options) async => options.method == 'POST'
          ? FakeAdapter.jsonResponse(const {
              'message': 'You may not message learners.',
              'code': 'PERMISSION_DENIED',
            }, status: 403)
          : FakeAdapter.jsonResponse(fixture('staff/submissions.json'));
      final c = container();
      c.listen(remindProvider, (_, _) {});

      final ok = await c.read(remindProvider.notifier).remind('a1');

      expect(ok, isFalse);
      expect(c.read(remindProvider).failure, isA<PermissionFailure>());
      expect(c.read(remindProvider).sent, isNull);
    });
  });
}
