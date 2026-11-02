import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../learner_home/learner_home.dart';
import '../data/assignments_api.dart';
import '../data/dto/learner_assignment.dart';

/// The assignment models the screens read (§26).
export '../data/dto/learner_assignment.dart';

/// Every assignment of every course this learner holds, in the order the server put them: by
/// deadline, soonest first.
final assignmentsProvider = FutureProvider<List<LearnerAssignment>>(
  (ref) => ref.watch(assignmentsApiProvider).assignments(),
);

/// One assignment. Auto-disposed: the state changes as soon as it is handed in or reviewed.
final assignmentProvider = FutureProvider.family<LearnerAssignment, String>(
  (ref, assignmentId) => ref.watch(assignmentsApiProvider).assignment(assignmentId),
  isAutoDispose: true,
);

/// Why this work cannot be handed in yet, mirroring `validateSubmission`
/// (`packages/domain/src/assignment.ts`). UX only — the server checks again and its refusal is
/// the one that counts (§16, §18).
@immutable
class SubmissionIssue {
  const SubmissionIssue(this.field, this.message);

  /// `text`, `files` or `chart`.
  final String field;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is SubmissionIssue && other.field == field && other.message == message;

  @override
  int get hashCode => Object.hash(field, message);
}

/// The same checks the server makes before it takes a submission.
List<SubmissionIssue> submissionIssues(CourseAssignment a, AssignmentWork work) {
  final issues = <SubmissionIssue>[];
  final words = work.wordCount;
  switch (a.format) {
    case SubmissionFormat.text:
      if (words == 0) {
        issues.add(const SubmissionIssue('text', 'Write your answer before submitting.'));
      }
      if (work.files.isNotEmpty) {
        issues.add(
          const SubmissionIssue('files', 'This assignment takes a written answer, not files.'),
        );
      }
    case SubmissionFormat.file:
      if (work.files.isEmpty) {
        issues.add(const SubmissionIssue('files', 'Upload your work before submitting.'));
      }
      if (work.files.length > AssignmentWork.maxSubmissionFiles) {
        issues.add(
          const SubmissionIssue(
            'files',
            'Upload at most ${AssignmentWork.maxSubmissionFiles} files.',
          ),
        );
      }
    case SubmissionFormat.chart:
      if (work.chart == null || work.chart!.isEmpty) {
        issues.add(const SubmissionIssue('chart', 'Add the birth details for the chart.'));
      }
      if (work.files.isNotEmpty) {
        issues.add(
          const SubmissionIssue(
            'files',
            'This assignment takes a chart and its interpretation, not files.',
          ),
        );
      }
    case SubmissionFormat.unknown:
      break;
  }
  if (a.format != SubmissionFormat.chart && !(work.chart?.isEmpty ?? true)) {
    issues.add(const SubmissionIssue('chart', 'This assignment does not take a chart.'));
  }
  // The word limit **is** enforced by the server (`validateSubmission`), so it is a real check
  // here too and not only guidance.
  if (a.format != SubmissionFormat.file && a.wordLimit != null && words > a.wordLimit!) {
    issues.add(
      SubmissionIssue('text', 'Keep your answer to ${a.wordLimit} words — it is $words now.'),
    );
  }
  return issues;
}

enum DraftStatus { idle, saving, saved, failed, offline }

@immutable
class AssignmentWorkState {
  const AssignmentWorkState({
    this.work = const AssignmentWork(),
    this.status = DraftStatus.idle,
    this.savedAt,
    this.submitting = false,
    this.refusal,
    this.failure,
  });

  final AssignmentWork work;
  final DraftStatus status;

  /// When the server stored the draft, in its own words.
  final DateTime? savedAt;
  final bool submitting;

  /// The academy's own sentence when it refused the hand-in (empty, already submitted, closed,
  /// deadline passed, access ended).
  final String? refusal;

  final AppFailure? failure;

  bool get busy => submitting || status == DraftStatus.saving;
}

/// The work area: what has been written, attached or filled in, kept on the server as a draft and
/// handed in when the learner says so. Nothing is kept on the device (§15).
///
/// It starts from what the server holds — the saved draft, else the work of a submission the
/// reviewer sent back — and starts again whenever that changes, which is what makes a hand-in
/// clear the area.
class AssignmentWorkController extends Notifier<AssignmentWorkState> {
  AssignmentWorkController(this.assignmentId);

  /// How long the typing has to stop before the draft is saved.
  static const autosave = Duration(seconds: 3);

  final String assignmentId;

  Timer? _timer;

  /// Work the server has not taken yet. It is what makes leaving the screen save: the provider is
  /// auto-disposed, and its disposal sends whatever is still outstanding.
  AssignmentWork? _unsaved;

  @override
  AssignmentWorkState build() {
    // Held now, so disposal can still send the last edit after the provider is gone.
    final api = ref.watch(assignmentsApiProvider);
    ref.onDispose(() {
      _timer?.cancel();
      final pending = _unsaved;
      _unsaved = null;
      if (pending == null || pending.text.length > AssignmentWork.maxTextLength) return;
      // Nothing is waiting for this: the screen has gone. A failure leaves the draft as it was.
      unawaited(
        api.saveDraft(assignmentId: assignmentId, work: pending).then((_) {}, onError: (_, _) {}),
      );
    });
    final row = ref.watch(assignmentProvider(assignmentId)).value;
    return AssignmentWorkState(work: row?.startingWork ?? const AssignmentWork());
  }

  void writeText(String text) => _edit(state.work.copyWith(text: text));

  void writeChart(BirthDetails chart) => _edit(state.work.copyWith(chart: chart));

  void addFile(Attachment file) {
    if (state.work.files.length >= AssignmentWork.maxFiles) return;
    _edit(state.work.copyWith(files: [...state.work.files, file]));
  }

  void removeFile(Attachment file) =>
      _edit(state.work.copyWith(files: [...state.work.files]..remove(file)));

  /// Saves what is on screen now — used by the explicit Save and when the screen goes away.
  Future<void> saveDraft() async {
    _timer?.cancel();
    if (state.work.text.length > AssignmentWork.maxTextLength) return;
    final saving = state.work;
    state = AssignmentWorkState(work: saving, status: DraftStatus.saving, savedAt: state.savedAt);
    try {
      final savedAt = await ref
          .read(assignmentsApiProvider)
          .saveDraft(assignmentId: assignmentId, work: saving);
      // Typing may have carried on while the request was in flight; keep what is on screen, and
      // only call it saved if what went up is still what is there.
      if (_unsaved == saving) _unsaved = null;
      state = AssignmentWorkState(work: state.work, status: DraftStatus.saved, savedAt: savedAt);
    } on ApiException catch (e) {
      final failure = e.failure;
      state = AssignmentWorkState(
        work: state.work,
        // Off the network the work is simply still here, unsaved — not an error the learner did.
        status: failure is NetworkFailure ? DraftStatus.offline : DraftStatus.failed,
        savedAt: state.savedAt,
        failure: failure is NetworkFailure ? null : failure,
      );
    }
  }

  /// Hands the work in. A 409 is the academy saying why not, and is shown as it stands.
  Future<bool> submit() async {
    if (state.busy) return false;
    _timer?.cancel();
    state = AssignmentWorkState(work: state.work, savedAt: state.savedAt, submitting: true);
    try {
      await ref.read(assignmentsApiProvider).submit(assignmentId: assignmentId, work: state.work);
      // It is handed in; there is no draft left to save on the way out.
      _unsaved = null;
      state = AssignmentWorkState(work: state.work, savedAt: state.savedAt);
      // The work area starts again from what the server now holds.
      ref.invalidate(assignmentProvider(assignmentId));
      ref.invalidate(assignmentsProvider);
      // Handing in can complete the lesson that delivers it, and with it the course.
      ref.invalidate(learnerHomeProvider);
      ref.invalidate(learnerCoursesProvider);
      return true;
    } on ApiException catch (e) {
      final failure = e.failure;
      state = AssignmentWorkState(
        work: state.work,
        savedAt: state.savedAt,
        refusal: failure is ConflictFailure ? failure.message : null,
        failure: failure is ConflictFailure ? null : failure,
      );
      return false;
    }
  }

  void clearRefusal() => state = AssignmentWorkState(work: state.work, savedAt: state.savedAt);

  void _edit(AssignmentWork work) {
    _timer?.cancel();
    _unsaved = work;
    state = AssignmentWorkState(work: work, savedAt: state.savedAt);
    _timer = Timer(autosave, () => unawaited(saveDraft()));
  }
}

final assignmentWorkProvider =
    NotifierProvider.family<AssignmentWorkController, AssignmentWorkState, String>(
      AssignmentWorkController.new,
      isAutoDispose: true,
    );
