import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

const _draftId = 'cmum8kcfr007vmmzwwd5td1b4';
const _returnedId = 'cmum8kcfo007tmmzwozrjpi3v';

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    adapter = FakeAdapter();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        child: const SizedBox(),
      ).overrides,
    );
  });

  /// Opens one assignment as the screen does: the detail is read, and the work area starts from
  /// whatever the server holds.
  Future<AssignmentWorkController> open(String id, String fixtureName) async {
    adapter.enqueueJson(fixture('learning/$fixtureName.json'));
    container.listen(assignmentProvider(id), (_, _) {});
    container.listen(assignmentWorkProvider(id), (_, _) {});
    await container.read(assignmentProvider(id).future);
    return container.read(assignmentWorkProvider(id).notifier);
  }

  /// The autosave runs on a real timer, so a test that waits for it waits a little longer.
  Future<void> settle([Duration wait = const Duration(milliseconds: 50)]) =>
      Future<void>.delayed(wait);

  test('the work area starts from the draft the server holds', () async {
    await open(_draftId, 'assignment-draft');

    expect(
      container.read(assignmentWorkProvider(_draftId)).work.text,
      startsWith('Mahadasha of Jupiter'),
    );
    expect(container.read(assignmentWorkProvider(_draftId)).status, DraftStatus.idle);
  });

  test('a returned hand-in starts from the work that was sent back', () async {
    await open(_returnedId, 'assignment-returned');

    final work = container.read(assignmentWorkProvider(_returnedId)).work;
    expect(work.text, startsWith('Sun in Leo'));
  });

  test('typing is saved once the typing stops, not on every keystroke', () async {
    final controller = await open(_draftId, 'assignment-draft');
    final before = adapter.requests.length;

    controller.writeText('First');
    await settle(AssignmentWorkController.autosave ~/ 2);
    controller.writeText('First and second');
    await settle(AssignmentWorkController.autosave ~/ 2);

    expect(
      adapter.requests.length,
      before,
      reason: 'each keystroke starts the wait again, so nothing has been sent yet',
    );

    adapter.enqueueJson({'savedAt': '2026-09-29T06:10:00.000Z'});
    await waitFor(
      () => container.read(assignmentWorkProvider(_draftId)).status == DraftStatus.saved,
      reason: 'the draft should be saved once the typing has stopped for the debounce',
    );

    expect(adapter.requests.length, before + 1, reason: 'one save for the whole burst');
    expect(adapter.lastRequest.method, 'PUT');
    expect((adapter.lastRequest.data! as Map)['text'], 'First and second');
    final state = container.read(assignmentWorkProvider(_draftId));
    expect(state.status, DraftStatus.saved);
    expect(state.savedAt, DateTime.utc(2026, 9, 29, 6, 10));
  });

  test('a draft that cannot reach the academy is kept, not lost', () async {
    final controller = await open(_draftId, 'assignment-draft');
    adapter.enqueueError(DioExceptionType.connectionError);

    controller.writeText('Written on a train.');
    await controller.saveDraft();

    final state = container.read(assignmentWorkProvider(_draftId));
    expect(state.status, DraftStatus.offline);
    expect(state.failure, isNull, reason: 'being offline is not an error the learner made');
    expect(state.work.text, 'Written on a train.');
  });

  test('leaving the screen saves what has not been saved yet', () async {
    final controller = await open(_draftId, 'assignment-draft');
    controller.writeText('Half a paragraph.');
    adapter.enqueueJson({'savedAt': '2026-09-29T06:10:00.000Z'});

    container.dispose();
    await waitFor(
      () => adapter.requests.any((r) => r.method == 'PUT'),
      reason: 'the outstanding draft should be sent as the screen goes away',
    );

    expect(adapter.lastRequest.method, 'PUT');
    expect((adapter.lastRequest.data! as Map)['text'], 'Half a paragraph.');
  });

  test('nothing is sent on the way out when there is nothing unsaved', () async {
    await open(_draftId, 'assignment-draft');
    final before = adapter.requests.length;

    container.dispose();
    await settle();

    expect(adapter.requests.length, before);
  });

  test('handing in refreshes what the server says about the assignment', () async {
    final controller = await open(_returnedId, 'assignment-returned');
    adapter.enqueueJson(fixture('learning/assignment-submitted.json'));
    // Read again after the hand-in, as the screen does.
    adapter.enqueueJson(fixture('learning/assignment-submitted.json'));

    final handedIn = await controller.submit();

    expect(handedIn, isTrue);
    expect(adapter.requests.map((r) => r.path), contains(endsWith('/submit')));
    final row = await container.read(assignmentProvider(_returnedId).future);
    expect(row.state, AssignmentState.submitted);
    expect(row.canSubmit, isFalse);
  });

  test('the academy\'s refusal is shown in its own words', () async {
    final controller = await open(_returnedId, 'assignment-returned');
    // The academy's own words, captured from the real route.
    adapter.enqueueJson(fixture('errors/assignment-empty.json'), status: 409);

    final handedIn = await controller.submit();

    expect(handedIn, isFalse);
    final state = container.read(assignmentWorkProvider(_returnedId));
    expect(state.refusal, 'Add your work before submitting.');
    expect(state.submitting, isFalse);
    expect(state.work.text, startsWith('Sun in Leo'), reason: 'the work is still there to fix');
    controller.clearRefusal();
    expect(container.read(assignmentWorkProvider(_returnedId)).refusal, isNull);
  });

  test('a hand-in cannot be sent twice while the first is in flight', () async {
    final controller = await open(_returnedId, 'assignment-returned');
    adapter.enqueueJson(fixture('learning/assignment-submitted.json'));
    adapter.enqueueJson(fixture('learning/assignment-submitted.json'));

    final first = controller.submit();
    final second = await controller.submit();
    await first;

    expect(second, isFalse);
    expect(adapter.requests.where((r) => r.path.endsWith('/submit')), hasLength(1));
  });

  group('the checks the server makes are made here first', () {
    const written = CourseAssignment(
      id: 'a',
      courseId: 'c',
      format: SubmissionFormat.text,
      wordLimit: 50,
    );
    const filed = CourseAssignment(id: 'a', courseId: 'c', format: SubmissionFormat.file);
    const charted = CourseAssignment(id: 'a', courseId: 'c', format: SubmissionFormat.chart);

    test('a written answer is needed, and files are not taken', () {
      expect(submissionIssues(written, const AssignmentWork()), [
        const SubmissionIssue('text', 'Write your answer before submitting.'),
      ]);
      expect(
        submissionIssues(
          written,
          const AssignmentWork(
            text: 'Here',
            files: [Attachment(id: 'm', name: 'a.pdf')],
          ),
        ),
        contains(
          const SubmissionIssue('files', 'This assignment takes a written answer, not files.'),
        ),
      );
    });

    test('the word limit is a real rule, not guidance — the route enforces it too', () {
      final tooLong = AssignmentWork(text: List.filled(51, 'word').join(' '));

      expect(submissionIssues(written, tooLong), [
        const SubmissionIssue('text', 'Keep your answer to 50 words — it is 51 now.'),
      ]);
      expect(
        submissionIssues(written, AssignmentWork(text: List.filled(50, 'w').join(' '))),
        isEmpty,
      );
    });

    test('a file hand-in needs a file, and no more than the route takes', () {
      expect(submissionIssues(filed, const AssignmentWork()), [
        const SubmissionIssue('files', 'Upload your work before submitting.'),
      ]);
      final tooMany = AssignmentWork(
        files: List.generate(
          AssignmentWork.maxSubmissionFiles + 1,
          (i) => Attachment(id: 'm$i', name: '$i.pdf'),
        ),
      );
      expect(
        submissionIssues(filed, tooMany),
        contains(const SubmissionIssue('files', 'Upload at most 3 files.')),
      );
    });

    test('a chart hand-in needs the birth details', () {
      expect(submissionIssues(charted, const AssignmentWork(text: 'Leo rising.')), [
        const SubmissionIssue('chart', 'Add the birth details for the chart.'),
      ]);
      expect(
        submissionIssues(
          charted,
          const AssignmentWork(
            text: 'Leo rising.',
            chart: BirthDetails(
              label: 'A friend',
              date: '1994-03-02',
              time: '05:40',
              place: 'Jaipur',
              lagna: 'Leo',
              moonSign: 'Taurus',
              nakshatra: 'Rohini',
            ),
          ),
        ),
        isEmpty,
      );
    });

    test('a chart is not sent where it does not belong', () {
      expect(
        submissionIssues(
          written,
          const AssignmentWork(
            text: 'Here',
            chart: BirthDetails(label: 'A friend'),
          ),
        ),
        contains(const SubmissionIssue('chart', 'This assignment does not take a chart.')),
      );
    });
  });
}
