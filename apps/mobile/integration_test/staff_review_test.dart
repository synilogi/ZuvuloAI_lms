import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';
import 'package:syniastrolms_mobile/features/staff_review/staff_review.dart';

/// Marking real coursework against the **real** API on the scratch database. Every score asserted
/// here is the server's own: the app never computes the grade it stores.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
const _learner = 'ananya@syniastrolms.test';

/// The assignment this suite marks. It is created once and reused, and every run leaves its one
/// hand-in waiting again, so nothing piles up and each run starts where the last one began.
const _assignmentTitle = 'Rubric fixture: word problem solution';
const _work =
    'Let the number of pencils be x. The shop sold x + 12 pens, and together they came to 60, so '
    '2x + 12 = 60. Taking 12 from both sides gives 2x = 48, so x = 24 pencils and 36 pens. As a '
    'check, 24 + 36 = 60 and 36 is 12 more than 24, so the answer fits the problem.';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  final clients = <String, ApiClient>{};

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<ApiClient> signIn(String email) async {
    final cached = clients[email];
    if (cached != null) return cached;
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clients[email] = clientFor(store);
  }

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  /// The rubric assignment, created on the first run and reused after that.
  Future<StaffAssignmentRow> rubricAssignment(ApiClient staff) async {
    final api = StaffReviewApi(staff);
    final existing = await api.assignments();
    final found = existing.rows.where((r) => r.assignment.title == _assignmentTitle).firstOrNull;
    if (found != null) return found;

    // It hangs off the course the seeded learner is enrolled in, so they can hand it in.
    final anySubmission = (await api.submissions(filter: 'graded')).rows.first;
    final sibling = existing.rows.firstWhere((r) => r.assignment.id == anySubmission.assignmentId);
    await staff.post(
      '/assignments',
      body: {
        'courseId': sibling.assignment.courseId,
        'title': _assignmentTitle,
        'instructions':
            'Solve the word problem you were given. Write the equation, solve it, and check '
            'the answer against the problem, explaining each step.',
        'format': 'text',
        'rubric': const [
          {'id': 'equation', 'title': 'Forming the equation', 'points': 20},
          {'id': 'solution', 'title': 'Solving it', 'points': 20},
          {'id': 'check', 'title': 'Checking the answer', 'points': 10},
        ],
        'maxScore': 50,
        'passMark': 30,
        'status': 'published',
      },
    );
    return (await api.assignments()).rows.firstWhere((r) => r.assignment.title == _assignmentTitle);
  }

  /// A hand-in on it that is waiting to be marked. A graded one is sent back and handed in again,
  /// so a second run has something to mark just as the first did.
  Future<SubmissionDetail> waitingSubmission() async {
    final staff = await signIn(_admin);
    final api = StaffReviewApi(staff);
    final assignment = (await rubricAssignment(staff)).assignment;
    final learner = AssignmentsApi(await signIn(_learner));

    /// The newest hand-in still waiting on this assignment. The route lists **every** attempt, so
    /// the one to mark is chosen by its review, never by its place in the list.
    Future<SubmissionRow?> waiting() async {
      final rows = (await api.submissions(assignmentId: assignment.id, sort: 'newest')).rows
          .where((r) => !r.isMissing)
          .where(
            (r) =>
                r.submission!.review.status == ReviewStatus.waiting ||
                r.submission!.review.status == ReviewStatus.inReview,
          );
      return rows.firstOrNull;
    }

    final found = await waiting();
    if (found != null) return api.submission(found.id);

    // Nothing is waiting: the last attempt was graded or returned. A graded one is sent back first,
    // because only a returned attempt may be handed in again.
    final latest = (await api.submissions(
      assignmentId: assignment.id,
      sort: 'newest',
    )).rows.where((r) => !r.isMissing).firstOrNull;
    if (latest != null && latest.submission!.review.status == ReviewStatus.graded) {
      await api.review(
        latest.id,
        decision: ReviewStatus.returned,
        feedback: 'Please look at the checking step again and hand it in once more.',
      );
    }
    await learner.submit(
      assignmentId: assignment.id,
      work: const AssignmentWork(text: _work),
    );
    final now = await waiting();
    return api.submission(now!.id);
  }

  testWidgets('the academy counts what is waiting, and an instructor sees only their own', (
    tester,
  ) async {
    await waitingSubmission();
    final academy = await StaffReviewApi(await signIn(_admin)).queue();
    final mine = await StaffReviewApi(await signIn(_instructor)).queue();

    expect(academy.toReview, greaterThan(0));
    expect(academy.overdue, lessThanOrEqualTo(academy.toReview));
    expect(mine.toReview, lessThanOrEqualTo(academy.toReview));
    expect(
      academy.byCourse.fold<int>(0, (n, c) => n + c.toReview),
      academy.toReview,
      reason: 'every waiting hand-in belongs to a course the route lists',
    );
  });

  testWidgets('an incomplete grade is refused, field by field, in the academy\'s words', (
    tester,
  ) async {
    final api = StaffReviewApi(await signIn(_admin));
    final detail = await waitingSubmission();

    try {
      await api.review(detail.submission.id, decision: ReviewStatus.graded, feedback: 'ok');
      fail('the academy should have refused a grade with no scores');
    } on ApiException catch (e) {
      final failure = e.failure;
      expect(failure, isA<ConflictFailure>());
      final issues = (failure as ConflictFailure).issues;
      expect(issues, isNotEmpty);
      // The rubric is scored criterion by criterion, so each unscored one is named — by its
      // criterion id beside the field, which is the only way to say which stepper is wrong.
      expect(issues.where((i) => i.key == 'scores'), hasLength(3));
      expect(
        issues.map((i) => i.criterionId).nonNulls,
        containsAll(['equation', 'solution', 'check']),
      );
      expect(issues.map((i) => i.key), contains('feedback'));
      for (final issue in issues) {
        expect(issue.message, isNotEmpty);
      }
    }

    // The refusal left the hand-in exactly where it was.
    expect(
      (await api.submission(detail.submission.id)).submission.review.status,
      ReviewStatus.waiting,
    );
  });

  testWidgets('a returned decision needs more than a word of explanation', (tester) async {
    final api = StaffReviewApi(await signIn(_admin));
    final detail = await waitingSubmission();

    await expectLater(
      api.review(detail.submission.id, decision: ReviewStatus.returned, feedback: 'no'),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).issues.single.key,
          'the field refused',
          'feedback',
        ),
      ),
    );
  });

  testWidgets('a draft review is kept, and is there again when it is opened', (tester) async {
    final api = StaffReviewApi(await signIn(_admin));
    final detail = await waitingSubmission();

    await api.review(
      detail.submission.id,
      decision: ReviewStatus.inReview,
      scores: const {'equation': 16, 'solution': 12},
      feedback: 'Halfway through this one.',
      privateNote: 'Second read needed on the checking step.',
    );

    final again = await api.submission(detail.submission.id);
    expect(again.submission.review.status, ReviewStatus.inReview);
    expect(again.submission.review.scores, const {'equation': 16, 'solution': 12});
    expect(again.submission.review.feedback, 'Halfway through this one.');
    // A draft is not a grade: nothing is scored yet.
    expect(again.submission.review.gradedScore, isNull);
  });

  testWidgets('the private note the reviewer keeps never reaches the learner', (tester) async {
    final api = StaffReviewApi(await signIn(_admin));
    final detail = await waitingSubmission();

    await api.review(
      detail.submission.id,
      decision: ReviewStatus.inReview,
      feedback: 'Coming along.',
      privateNote: 'A note only the teaching team should read.',
    );

    final asLearner = await AssignmentsApi(await signIn(_learner)).assignment(detail.assignment.id);

    expect(asLearner.submission, isNotNull);
    expect(asLearner.submission!.review.feedback, 'Coming along.');
    // The model has no room for it, and the route sends none: read the raw body to be sure.
    final raw = await (await signIn(_learner)).get('/learning/assignments/${detail.assignment.id}');
    expect(raw.toString(), isNot(contains('only the teaching team')));
  });

  testWidgets('a grade is the academy\'s arithmetic, and the learner is told', (tester) async {
    final api = StaffReviewApi(await signIn(_admin));
    final detail = await waitingSubmission();
    final before = await api.queue();

    final graded = await api.review(
      detail.submission.id,
      decision: ReviewStatus.graded,
      scores: const {'equation': 18, 'solution': 15, 'check': 8},
      feedback: 'Clear and well argued, especially the moon sign.',
    );

    expect(graded.review.status, ReviewStatus.graded);
    // 18 + 15 + 8 = 41, and the hand-in was not late, so the academy keeps all of it.
    expect(graded.review.score, 41);
    expect(
      reviewScore(
        detail.assignment,
        scores: const {'equation': 18, 'solution': 15, 'check': 8},
        late: detail.submission.late,
      ).score,
      graded.review.score,
      reason: 'the estimate the app shows matches what the academy worked out',
    );

    // One fewer waiting.
    expect((await api.queue()).toReview, before.toReview - 1);

    // The learner reads their own grade, from their own route.
    final asLearner = await AssignmentsApi(await signIn(_learner)).assignment(detail.assignment.id);
    expect(asLearner.state, AssignmentState.graded);
    expect(asLearner.submission!.review.gradedScore, 41);
    expect(asLearner.submission!.review.feedback, contains('moon sign'));
  });

  testWidgets('a returned hand-in can be handed in again', (tester) async {
    final api = StaffReviewApi(await signIn(_admin));
    final detail = await waitingSubmission();

    await api.review(
      detail.submission.id,
      decision: ReviewStatus.returned,
      feedback: 'Have another look at the checking step and hand it in again.',
    );

    final learner = AssignmentsApi(await signIn(_learner));
    final returned = await learner.assignment(detail.assignment.id);
    expect(returned.isReturned, isTrue);
    expect(returned.canSubmit, isTrue, reason: 'a return is an invitation to try again');
    // The work they get back is their own, so they can edit rather than start over.
    expect(returned.startingWork.text, isNotEmpty);

    final again = await learner.submit(
      assignmentId: detail.assignment.id,
      work: const AssignmentWork(text: _work),
    );
    expect(again.submission!.attempt, greaterThan(1));
    expect(again.submission!.review.status, ReviewStatus.waiting);
  });

  testWidgets('who still owes an assignment is the academy\'s answer, and it reminds them', (
    tester,
  ) async {
    final api = StaffReviewApi(await signIn(_admin));
    final assignment = (await rubricAssignment(await signIn(_admin))).assignment;

    final missing = (await api.submissions(assignmentId: assignment.id, filter: 'missing')).rows;
    expect(missing, isNotEmpty);
    for (final row in missing) {
      expect(row.isMissing, isTrue);
      expect(row.id, startsWith('missing-'));
      expect(row.student.name, isNotEmpty);
    }

    // One learner, so a run leaves one notice behind rather than dozens.
    final sent = await api.remind(assignment.id, studentIds: [missing.first.student.id]);
    expect(sent, 1);

    // Someone who has handed in is never reminded, whatever is asked for.
    final handedIn = (await api.submissions(
      assignmentId: assignment.id,
    )).rows.firstWhere((r) => !r.isMissing);
    expect(await api.remind(assignment.id, studentIds: [handedIn.student.id]), 0);
  });

  testWidgets('a learner has no queue to read', (tester) async {
    await expectLater(
      StaffReviewApi(await signIn(_learner)).queue(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });
}
