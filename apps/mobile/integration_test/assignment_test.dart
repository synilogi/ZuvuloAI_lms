import 'dart:io';

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
import 'package:syniastrolms_mobile/features/assignments/data/assignments_api.dart';
import 'package:syniastrolms_mobile/features/assignments/data/dto/learner_assignment.dart';
import 'package:syniastrolms_mobile/features/course_learning/data/course_learning_api.dart';
import 'package:syniastrolms_mobile/features/media/data/media_api.dart';

/// Handing coursework in against the **real** API on the scratch database
/// (`tool/contract_server.sh start`). Nothing here asserts anything the app worked out for itself:
/// the state, the score and every refusal come from the server.
const _password = 'syniastrolms123';

/// The course whose seeded assignment takes a written answer, and the instructor who teaches it
/// (`apps/api/prisma/academyDemo.ts`, run by `apps/api/prisma/seed.ts`).
const _courseSlug = 'maths-foundations';
const _instructor = 'meenakshi@syniastrolms.test';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  late Directory temp;
  late String courseId;

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  /// One signed-in client per account for the whole run: a token does not go stale here, and
  /// every extra sign-in is another connection the emulator has to make.
  final clients = <String, ApiClient>{};

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

  setUpAll(() async {
    config = AppConfig.fromEnvironment(Flavor.dev);
    temp = Directory.systemTemp.createTempSync('assignment_integration');
    final course =
        (await clientFor(_Token()).get('/catalog/courses/$_courseSlug'))! as Map<String, dynamic>;
    courseId = course['id']! as String;
  });

  tearDownAll(() => temp.deleteSync(recursive: true));

  /// A real PDF, as the server checks the first bytes against the extension (SAAS-023).
  File pdf(String name) =>
      File('${temp.path}/$name')
        ..writeAsBytesSync([...'%PDF-1.4'.codeUnits, ...List.filled(512, 7)]);

  /// The learner, enrolled in the course. Enrolling twice is the academy's own refusal, and means
  /// an earlier run already did it.
  final enrolled = <String>{};

  Future<ApiClient> learnerOn(String email) async {
    final client = await signIn(email);
    if (enrolled.add(email)) {
      try {
        await CourseLearningApi(client).enroll(courseId);
      } on ApiException catch (e) {
        if (e.failure is! ConflictFailure) rethrow;
      }
    }
    return client;
  }

  Future<LearnerAssignment> writtenAssignment(ApiClient client) async {
    final rows = await AssignmentsApi(client).assignments();
    return rows.firstWhere(
      (r) => r.assignment.courseId == courseId && r.assignment.format == SubmissionFormat.text,
    );
  }

  /// The row the academy holds for one learner's latest hand-in. A learner may have several
  /// attempts, and only the last one is the one the learner is shown.
  Future<Map<String, dynamic>?> submissionRowOf({
    required ApiClient staff,
    required String assignmentId,
    required String email,
  }) async {
    // Newest first and a big page: the scratch database accumulates an attempt on every run, and
    // the default twenty-row page would leave this run's hand-in off the end.
    final body =
        (await staff.get(
              '/assignments/$assignmentId/submissions',
              query: {'sort': 'newest', 'pageSize': 200},
            ))!
            as Map<String, dynamic>;
    final rows =
        (body['rows']! as List<dynamic>).cast<Map<String, dynamic>>().where((row) {
          final student = row['student']! as Map<String, dynamic>;
          return student['email'] == email && row['submission'] != null;
        }).toList()..sort((a, b) {
          int attempt(Map<String, dynamic> row) =>
              (row['submission']! as Map<String, dynamic>)['attempt']! as int;
          return attempt(a).compareTo(attempt(b));
        });
    return rows.lastOrNull;
  }

  /// Makes the assignment open to a hand-in again, whatever an earlier run left behind: the
  /// academy only takes another attempt once a reviewer has sent the last one back. This is the
  /// real review route, not a database edit.
  Future<void> allowAnotherAttempt({
    required String assignmentId,
    required String email,
    String feedback = 'Please show the division for the second example and hand this in again.',
  }) async {
    final staff = await signIn(_instructor);
    final row = await submissionRowOf(staff: staff, assignmentId: assignmentId, email: email);
    if (row == null) return;
    final review = (row['submission']! as Map<String, dynamic>)['review']! as Map<String, dynamic>;
    if (review['status'] == 'returned') return;
    await staff.post(
      '/assignments/submissions/${row['id']}/review',
      body: {'decision': 'returned', 'feedback': feedback},
    );
  }

  testWidgets('a draft keeps the written work and an uploaded file on the server', (tester) async {
    const email = 'arjun@syniastrolms.test';
    final client = await learnerOn(email);
    final api = AssignmentsApi(client);
    final row = await writtenAssignment(client);
    await allowAnotherAttempt(assignmentId: row.assignment.id, email: email);

    final uploaded = await MediaApi(client).upload(
      filePath: pdf('working-notes.pdf').path,
      fileName: 'working-notes.pdf',
      mimeType: 'application/pdf',
    );

    final savedAt = await api.saveDraft(
      assignmentId: row.assignment.id,
      work: AssignmentWork(
        text: 'Recipe: 3/4 cup of milk is 0.75, which is 75%; the bill shows 0.5 units.',
        files: [
          Attachment(
            id: uploaded.id,
            name: uploaded.name,
            sizeMb: uploaded.sizeMb,
            url: uploaded.url,
            mime: uploaded.mime,
          ),
        ],
      ),
    );

    expect(savedAt.isUtc, isTrue);
    // Read back from the server, not from anything the app kept.
    final reloaded = await api.assignment(row.assignment.id);
    final draft = reloaded.draft!;
    expect(draft.text, startsWith('Recipe: 3/4 cup'));
    expect(draft.files.single.id, uploaded.id);
    expect(
      draft.files.single.name,
      'working-notes.pdf',
      reason: 'the name comes from the stored file, not from the request',
    );
    expect(reloaded.startingWork.text, draft.text, reason: 'the work area starts from the draft');
  });

  testWidgets('a file that is not the learner\'s own upload is refused', (tester) async {
    const email = 'arjun@syniastrolms.test';
    final client = await learnerOn(email);
    final staff = await signIn(_instructor);
    final row = await writtenAssignment(client);

    final theirs = await MediaApi(staff).upload(
      filePath: pdf('instructor-notes.pdf').path,
      fileName: 'instructor-notes.pdf',
      mimeType: 'application/pdf',
    );

    await expectLater(
      AssignmentsApi(client).saveDraft(
        assignmentId: row.assignment.id,
        work: AssignmentWork(
          files: [Attachment(id: theirs.id, name: theirs.name, sizeMb: theirs.sizeMb)],
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          contains('not an upload of yours'),
        ),
      ),
    );
  });

  testWidgets('handing in the written work succeeds, and the server says it is submitted', (
    tester,
  ) async {
    const email = 'arjun@syniastrolms.test';
    final client = await learnerOn(email);
    final api = AssignmentsApi(client);
    final row = await writtenAssignment(client);
    await allowAnotherAttempt(assignmentId: row.assignment.id, email: email);

    // A written hand-in is the answer itself; this format takes no files.
    final handedIn = await api.submit(
      assignmentId: row.assignment.id,
      work: const AssignmentWork(
        text:
            'Recipe: 3/4 cup = 0.75 = 75%. Bill: 1/2 unit = 0.5 = 50%. Label: 1/4 tablet = 0.25 = 25%.',
      ),
    );

    expect(handedIn.state, AssignmentState.submitted);
    expect(handedIn.submission!.review.status, ReviewStatus.waiting);
    expect(handedIn.submission!.text, startsWith('Recipe: 3/4 cup'));
    expect(handedIn.canSubmit, isFalse, reason: 'it is with the instructor now');
    expect(handedIn.draft, isNull, reason: 'the draft is cleared once it is handed in');

    // And the same thing read fresh, in the list as well as on its own.
    final again = await api.assignment(row.assignment.id);
    expect(again.state, AssignmentState.submitted);
    expect(
      (await api.assignments())
          .firstWhere((r) => r.assignment.id == row.assignment.id)
          .submission!
          .review
          .status,
      ReviewStatus.waiting,
    );
  });

  testWidgets('what the instructor grades is what the learner then sees', (tester) async {
    const email = 'arjun@syniastrolms.test';
    final client = await learnerOn(email);
    final api = AssignmentsApi(client);
    final row = await writtenAssignment(client);
    await allowAnotherAttempt(assignmentId: row.assignment.id, email: email);
    await api.submit(
      assignmentId: row.assignment.id,
      work: const AssignmentWork(text: 'Recipe: 3/4 cup = 0.75 = 75%.'),
    );

    final staff = await signIn(_instructor);
    final pending = await submissionRowOf(
      staff: staff,
      assignmentId: row.assignment.id,
      email: email,
    );
    await staff.post(
      '/assignments/submissions/${pending!['id']}/review',
      body: {
        'decision': 'graded',
        'points': 78,
        'feedback': 'A clear conversion of the recipe. Say more about the bill next time.',
      },
    );

    final graded = await api.assignment(row.assignment.id);

    expect(graded.state, AssignmentState.graded);
    final review = graded.submission!.review;
    expect(review.status, ReviewStatus.graded);
    expect(review.gradedScore, 78, reason: 'the score is the academy\'s, after its own policy');
    expect(review.feedback, contains('recipe'));
    expect(graded.assignment.totalPoints, 100);
    expect(review.gradedScore!, greaterThanOrEqualTo(graded.assignment.passMark));
    expect(graded.canSubmit, isFalse);
  });

  testWidgets('a hand-in the reviewer sends back can be written again and handed in again', (
    tester,
  ) async {
    const email = 'vikram@syniastrolms.test';
    final client = await learnerOn(email);
    final api = AssignmentsApi(client);
    final row = await writtenAssignment(client);
    await allowAnotherAttempt(assignmentId: row.assignment.id, email: email);
    final first = await api.submit(
      assignmentId: row.assignment.id,
      work: const AssignmentWork(text: 'A first attempt at the conversions.'),
    );

    final staff = await signIn(_instructor);
    final pending = await submissionRowOf(
      staff: staff,
      assignmentId: row.assignment.id,
      email: email,
    );
    await staff.post(
      '/assignments/submissions/${pending!['id']}/review',
      body: {
        'decision': 'returned',
        'feedback': 'Please add the percentage for each example and hand this in once more.',
      },
    );

    final returned = await api.assignment(row.assignment.id);
    // The documented quirk: the state reads as a draft, and the review is what says it came back.
    expect(returned.state, AssignmentState.draft);
    expect(returned.isReturned, isTrue);
    expect(returned.canSubmit, isTrue);
    expect(returned.submission!.review.gradedScore, isNull, reason: 'it was not given a grade');
    expect(
      returned.startingWork.text,
      'A first attempt at the conversions.',
      reason: 'the work area starts from what was sent back',
    );

    final resubmitted = await api.submit(
      assignmentId: row.assignment.id,
      work: AssignmentWork(text: '${returned.startingWork.text} 3/4 is 75%.'),
    );

    expect(resubmitted.state, AssignmentState.submitted);
    expect(resubmitted.submission!.attempt, first.submission!.attempt + 1);
    expect(resubmitted.submission!.text, endsWith('3/4 is 75%.'));
    expect(resubmitted.submission!.review.status, ReviewStatus.waiting);
  });

  testWidgets('an empty hand-in is refused by the academy, in its own words', (tester) async {
    const email = 'meera@syniastrolms.test';
    final client = await learnerOn(email);
    final row = await writtenAssignment(client);
    await allowAnotherAttempt(assignmentId: row.assignment.id, email: email);

    // The app does not offer this — the button is disabled — so this is the guard behind it.
    await expectLater(
      AssignmentsApi(client).submit(assignmentId: row.assignment.id, work: const AssignmentWork()),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          'Add your work before submitting.',
        ),
      ),
    );
  });

  testWidgets('a learner sees only their own coursework', (tester) async {
    final arjun = await learnerOn('arjun@syniastrolms.test');
    final meera = await learnerOn('meera@syniastrolms.test');

    final theirs = await AssignmentsApi(arjun).assignments();
    final others = await AssignmentsApi(meera).assignments();

    // Both are enrolled in the same course, so they see the same assignment — with their own work
    // on it and nobody else's.
    final shared = theirs.firstWhere((r) => r.assignment.courseId == courseId);
    final same = others.firstWhere((r) => r.assignment.id == shared.assignment.id);
    expect(same.submission?.id, isNot(shared.submission?.id));
    for (final row in [...theirs, ...others]) {
      expect(row.assignment.status, isNot('draft'), reason: 'an unpublished assignment is hidden');
    }
  });
}
