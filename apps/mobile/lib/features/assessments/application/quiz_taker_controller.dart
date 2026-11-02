import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_decoder.dart';
import '../../../core/platform/clock.dart';
import '../../../shared/domain/quiz.dart';
import '../../learner_home/learner_home.dart';
import '../data/assessments_api.dart';
import '../data/dto/assessment_row.dart';
import '../data/dto/quiz_attempt.dart';

/// The assessment models the screens read (§26).
export '../../../core/network/error_decoder.dart'
    show EnrollmentFailure, EnrollmentProblem, QuizSessionFailure, QuizSessionProblem;
export '../data/dto/assessment_row.dart';
export '../data/dto/quiz_attempt.dart';

/// The learner's assessments across every course they hold.
final assessmentsProvider = FutureProvider<List<AssessmentRow>>(
  (ref) => ref.watch(assessmentsApiProvider).assessments(),
);

/// The quiz a lesson delivers, by its course and lesson.
typedef QuizRef = ({String courseId, String lessonId});

/// Where the learner is in a quiz.
enum QuizPhase {
  /// Reading where the learner stands, or picking up the attempt still open.
  loading,

  /// What the quiz is, before starting.
  intro,
  answering,

  /// Looking over the answers before handing them in.
  review,

  /// Handing in.
  submitting,

  /// The server's result.
  result,
}

/// Where the answer sheet stands against the server. Answers count only once the server has
/// accepted them, so "answered on this phone" and "saved" are never the same thing.
enum QuizSaveStatus {
  /// Nothing changed since the attempt was opened.
  idle,

  /// Answered on this phone, not sent yet.
  unsaved,
  saving,

  /// The server has the sheet as it stands.
  saved,

  /// The network or the server failed; sending again on its own.
  retrying,

  /// Sending stopped; the learner can try again.
  failed,
}

/// The countdown crossed a threshold worth saying out loud.
enum TimeWarning { fiveMinutes, oneMinute }

/// The waits a quiz uses — a test shortens them.
@immutable
class QuizTimings {
  const QuizTimings({
    this.saveDelay = const Duration(milliseconds: 800),
    this.tick = const Duration(seconds: 1),
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 15),
    ],
  });

  /// How long after the last change the sheet is saved.
  final Duration saveDelay;

  /// How often the countdown is redrawn.
  final Duration tick;

  /// The waits before sending again after a network or server failure; past the last, a save
  /// stops and waits for the learner, and a hand-in keeps trying at the last.
  final List<Duration> retryDelays;
}

final quizTimingsProvider = Provider<QuizTimings>((ref) => const QuizTimings());

const Object _keep = Object();

@immutable
class QuizTakerState {
  const QuizTakerState({
    this.phase = QuizPhase.loading,
    this.quiz,
    this.standing,
    this.history = const [],
    this.session,
    this.questions = const [],
    this.answers = const {},
    this.savedAnswers = const {},
    this.index = 0,
    this.remaining,
    this.save = QuizSaveStatus.idle,
    this.saveFailure,
    this.savedAt,
    this.timeUp = false,
    this.starting = false,
    this.result,
    this.completion,
    this.expired = false,
    this.refusal,
    this.opensAt,
    this.failure,
    this.warning,
  });

  final QuizPhase phase;

  /// The quiz as the lesson describes it: what to show before an attempt. Never answered from.
  final LearnerQuiz? quiz;

  /// Where the learner stands, by the server.
  final QuizStanding? standing;

  /// Attempts handed in, newest first, cut by the server to what the learner may see.
  final List<AttemptReview> history;

  /// The attempt under way.
  final QuizSessionView? session;

  /// The attempt's questions, as the server sent them when it started or resumed it — in the
  /// order it fixed. Empty until then.
  final List<LearnerQuizQuestion> questions;

  /// Question id → the chosen option ids, or the typed answer, on this phone. Never a score.
  final Map<String, Object> answers;

  /// The answers the server has confirmed it holds.
  final Map<String, Object> savedAnswers;

  /// Which question is on screen.
  final int index;

  /// Time left by the server's clock, measured on this phone's monotonic clock since the server
  /// last said; null when untimed.
  final Duration? remaining;

  final QuizSaveStatus save;

  /// Why the last save failed.
  final AppFailure? saveFailure;
  final DateTime? savedAt;

  /// The deadline has passed: answers are locked and the attempt is being handed in.
  final bool timeUp;

  /// The server is starting — or picking up — the attempt.
  final bool starting;

  /// The handed-in attempt, as the server reviewed it.
  final AttemptReview? result;

  /// What passing completed, when it did.
  final CompleteResult? completion;

  /// The attempt was handed in at the deadline, on the answers saved by then.
  final bool expired;

  /// The academy's own sentence when it refused (all attempts used, a retake wait, closed, access
  /// paused or ended).
  final String? refusal;

  /// When a quiz that refused to start because it has not opened yet opens.
  final DateTime? opensAt;

  /// A failure that is not the academy speaking (offline, a server error).
  final AppFailure? failure;

  /// The last threshold the countdown crossed.
  final TimeWarning? warning;

  /// Whether [question] has an answer worth sending.
  bool answered(LearnerQuizQuestion question) => _hasAnswer(answers[question.id]);

  /// Whether the server holds [question]'s answer as it stands on this phone.
  bool savedOnServer(LearnerQuizQuestion question) =>
      _sameAnswer(answers[question.id], savedAnswers[question.id]);

  int get unansweredCount => questions.where((q) => !answered(q)).length;

  bool get busy => phase == QuizPhase.submitting;

  /// An attempt is under way on this screen: leaving it leaves the timer running.
  bool get inAttempt =>
      (phase == QuizPhase.answering ||
          phase == QuizPhase.review ||
          phase == QuizPhase.submitting) &&
      session != null;

  /// Answers can no longer change.
  bool get locked => timeUp || phase == QuizPhase.submitting || phase == QuizPhase.result;

  bool get isTimed => remaining != null;

  /// A save is not yet confirmed by the server.
  bool get hasUnsaved =>
      save == QuizSaveStatus.unsaved ||
      save == QuizSaveStatus.saving ||
      save == QuizSaveStatus.retrying ||
      save == QuizSaveStatus.failed;

  QuizTakerState copyWith({
    QuizPhase? phase,
    Object? quiz = _keep,
    Object? standing = _keep,
    List<AttemptReview>? history,
    Object? session = _keep,
    List<LearnerQuizQuestion>? questions,
    Map<String, Object>? answers,
    Map<String, Object>? savedAnswers,
    int? index,
    Object? remaining = _keep,
    QuizSaveStatus? save,
    Object? saveFailure = _keep,
    Object? savedAt = _keep,
    bool? timeUp,
    bool? starting,
    Object? result = _keep,
    Object? completion = _keep,
    bool? expired,
    Object? refusal = _keep,
    Object? opensAt = _keep,
    Object? failure = _keep,
    Object? warning = _keep,
  }) => QuizTakerState(
    phase: phase ?? this.phase,
    quiz: identical(quiz, _keep) ? this.quiz : quiz as LearnerQuiz?,
    standing: identical(standing, _keep) ? this.standing : standing as QuizStanding?,
    history: history ?? this.history,
    session: identical(session, _keep) ? this.session : session as QuizSessionView?,
    questions: questions ?? this.questions,
    answers: answers ?? this.answers,
    savedAnswers: savedAnswers ?? this.savedAnswers,
    index: index ?? this.index,
    remaining: identical(remaining, _keep) ? this.remaining : remaining as Duration?,
    save: save ?? this.save,
    saveFailure: identical(saveFailure, _keep) ? this.saveFailure : saveFailure as AppFailure?,
    savedAt: identical(savedAt, _keep) ? this.savedAt : savedAt as DateTime?,
    timeUp: timeUp ?? this.timeUp,
    starting: starting ?? this.starting,
    result: identical(result, _keep) ? this.result : result as AttemptReview?,
    completion: identical(completion, _keep) ? this.completion : completion as CompleteResult?,
    expired: expired ?? this.expired,
    refusal: identical(refusal, _keep) ? this.refusal : refusal as String?,
    opensAt: identical(opensAt, _keep) ? this.opensAt : opensAt as DateTime?,
    failure: identical(failure, _keep) ? this.failure : failure as AppFailure?,
    warning: identical(warning, _keep) ? this.warning : warning as TimeWarning?,
  );
}

bool _hasAnswer(Object? answer) => switch (answer) {
  final String text => text.trim().isNotEmpty,
  final List<Object?> ids => ids.isNotEmpty,
  _ => false,
};

bool _sameAnswer(Object? a, Object? b) {
  if (!_hasAnswer(a) && !_hasAnswer(b)) return true;
  if (a is String && b is String) return a.trim() == b.trim();
  if (a is List && b is List) return setEquals(a.toSet(), b.toSet());
  return false;
}

/// Taking a lesson's quiz through a session the server runs. Starting asks the server, which
/// starts the attempt — or picks the open one up — and only then sends the questions, the answers
/// it holds and the time it says is left. Every change is saved a moment later as the whole sheet,
/// numbered so a late answer can never overwrite a newer one; the server keeps it only before its
/// deadline. At zero the attempt is handed in. Nothing here marks an answer, and no time this
/// phone's wall clock says is trusted.
class QuizTakerController extends Notifier<QuizTakerState> {
  QuizTakerController(this.target);

  final QuizRef target;

  late AssessmentsApi _api;
  late MonotonicClock _clock;
  late QuizTimings _timings;

  Timer? _ticker;
  Timer? _debounce;
  Timer? _retry;

  /// The number of the last sheet sent, and of the last one the server confirmed it kept.
  int _seq = 0;
  int _confirmedSeq = 0;

  /// Edits made on this phone, and how many of them the confirmed sheet carries.
  int _version = 0;
  int _confirmedVersion = 0;
  bool _saveInFlight = false;
  int _saveFailures = 0;

  /// The server's remaining time when it last said, and when that was on the monotonic clock.
  int? _remainingSec;
  Duration _syncedAt = Duration.zero;
  DateTime? _syncedServerNow;
  bool _warnedFive = false;
  bool _warnedOne = false;

  /// One per Start tap, sent again with a retry of that tap's request.
  String? _startKey;
  bool _handingIn = false;
  bool _handedIn = false;
  int _handInFailures = 0;
  bool _disposed = false;

  bool get _dirty => _version != _confirmedVersion;

  /// The attempt under way and its sheet on this phone, kept outside the state for disposal.
  String? _openSessionId;
  Map<String, Object> _sheet = const {};

  @override
  QuizTakerState build() {
    _api = ref.watch(assessmentsApiProvider);
    _clock = ref.watch(monotonicClockProvider);
    _timings = ref.watch(quizTimingsProvider);
    ref.onDispose(() {
      _disposed = true;
      _ticker?.cancel();
      _debounce?.cancel();
      _retry?.cancel();
      // Leaving the lesson sends what is still unsaved; the attempt itself stays open. (The state
      // cannot be read while the provider is disposed, so the sheet is the copy kept for this.)
      final sessionId = _openSessionId;
      if (_dirty && sessionId != null && !_handedIn && !_handingIn) {
        _api
            .saveAnswers(
              courseId: target.courseId,
              lessonId: target.lessonId,
              sessionId: sessionId,
              answers: _sheet,
              seq: ++_seq,
            )
            .ignore();
      }
    });
    return const QuizTakerState();
  }

  /// Shows [quiz] as its lesson describes it, then asks the server where the learner stands — and
  /// picks up the attempt still open, if there is one.
  void open(LearnerQuiz quiz) {
    if (state.quiz?.id == quiz.id && state.phase != QuizPhase.loading) {
      state = state.copyWith(quiz: quiz);
      return;
    }
    state = QuizTakerState(quiz: quiz);
    unawaited(load());
  }

  /// Reads where the learner stands and their attempts; resumes the open attempt.
  Future<void> load() async {
    state = state.copyWith(phase: QuizPhase.loading, failure: null);
    try {
      final read = await _api.attempts(courseId: target.courseId, lessonId: target.lessonId);
      if (_disposed) return;
      state = state.copyWith(standing: read.standing, history: read.attempts);
      // An open attempt is picked up — unless the server says it may not be (access paused or
      // ended): then the intro says why, and offers no way back in.
      if ((read.standing.openSession?.isActive ?? false) && read.standing.canStart) {
        await _resume();
      } else {
        state = state.copyWith(phase: QuizPhase.intro);
      }
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(phase: QuizPhase.intro, failure: e.failure);
    }
  }

  /// Picks the open attempt up without starting anything.
  Future<void> _resume() async {
    final latest = await _api.latestSession(courseId: target.courseId, lessonId: target.lessonId);
    if (_disposed) return;
    if (latest == null) {
      state = state.copyWith(phase: QuizPhase.intro);
    } else if (latest.session.isActive) {
      _adopt(latest);
    } else {
      await _showFinished(latest.session);
    }
  }

  /// Starts the attempt on the server — or picks up the open one — and only now holds its
  /// questions. Starting uses an attempt; a refusal keeps the intro and says why.
  Future<void> start() async {
    if (state.starting || state.inAttempt || _handingIn) return;
    _startKey ??= newStartKey();
    state = state.copyWith(starting: true, refusal: null, opensAt: null, failure: null);
    try {
      final begun = await _api.startSession(
        courseId: target.courseId,
        lessonId: target.lessonId,
        startKey: _startKey,
      );
      if (_disposed) return;
      _startKey = null;
      ref.invalidate(assessmentsProvider);
      if (begun.session.isActive) {
        _adopt(begun);
      } else {
        await _showFinished(begun.session);
      }
    } on ApiException catch (e) {
      if (_disposed) return;
      final failure = e.failure;
      final retryable = _isTransient(failure);
      // A refused start was not made: the next tap is a new one. A lost one may have been, so its
      // retry carries the same key and the server answers with the session it made.
      if (!retryable) _startKey = null;
      state = state.copyWith(
        starting: false,
        refusal: failure is ConflictFailure ? failure.message : null,
        opensAt: failure is QuizSessionFailure ? failure.opensAt : null,
        failure: failure is ConflictFailure ? null : failure,
      );
      if (failure is ConflictFailure) unawaited(_refreshStanding());
    }
  }

  void _adopt(QuizSessionStart begun) {
    final session = begun.session;
    final sheet = session.answerSheet;
    _seq = session.answersSeq;
    _confirmedSeq = session.answersSeq;
    _version = 0;
    _confirmedVersion = 0;
    _saveFailures = 0;
    _handedIn = false;
    _handingIn = false;
    _handInFailures = 0;
    _syncedServerNow = null;
    _sync(session, force: true);
    _openSessionId = session.id;
    _sheet = sheet;
    final left = _remainingNow();
    _warnedFive = left != null && left <= const Duration(minutes: 5);
    _warnedOne = left != null && left <= const Duration(minutes: 1);
    state = state.copyWith(
      phase: QuizPhase.answering,
      session: session,
      questions: begun.questions,
      answers: sheet,
      savedAnswers: sheet,
      index: 0,
      remaining: left,
      save: session.savedAt == null ? QuizSaveStatus.idle : QuizSaveStatus.saved,
      saveFailure: null,
      savedAt: session.savedAt,
      timeUp: false,
      starting: false,
      result: null,
      completion: null,
      expired: false,
      refusal: null,
      opensAt: null,
      failure: null,
      warning: null,
    );
    _ticker?.cancel();
    if (left != null) {
      _ticker = Timer.periodic(_timings.tick, (_) => tick());
      if (left <= Duration.zero) _timeUp();
    }
  }

  /// Takes the server's time from [session] — only from an answer at least as new as the last one,
  /// so a late response never winds the clock back.
  void _sync(QuizSessionView session, {bool force = false}) {
    final serverNow = session.serverNow;
    final last = _syncedServerNow;
    if (!force && last != null && serverNow != null && serverNow.isBefore(last)) return;
    _remainingSec = session.remainingSec;
    _syncedAt = _clock();
    _syncedServerNow = serverNow;
  }

  Duration? _remainingNow() {
    final secs = _remainingSec;
    if (secs == null) return null;
    final left = Duration(seconds: secs) - (_clock() - _syncedAt);
    return left < Duration.zero ? Duration.zero : left;
  }

  /// Redraws the countdown — every [QuizTimings.tick]. At zero the answers lock and the attempt is
  /// handed in; the server keeps only what it accepted in time.
  @visibleForTesting
  void tick() {
    if (_disposed || _handedIn) return;
    if (state.phase != QuizPhase.answering && state.phase != QuizPhase.review) return;
    final left = _remainingNow();
    if (left == null) return;
    TimeWarning? warning;
    if (!_warnedOne && left <= const Duration(minutes: 1) && left > Duration.zero) {
      _warnedOne = true;
      _warnedFive = true;
      warning = TimeWarning.oneMinute;
    } else if (!_warnedFive && left <= const Duration(minutes: 5) && left > Duration.zero) {
      _warnedFive = true;
      warning = TimeWarning.fiveMinutes;
    }
    state = warning == null
        ? state.copyWith(remaining: left)
        : state.copyWith(remaining: left, warning: warning);
    if (left <= Duration.zero) _timeUp();
  }

  void _timeUp() {
    if (_handingIn || _handedIn) return;
    _ticker?.cancel();
    _debounce?.cancel();
    _retry?.cancel();
    _openSessionId = null;
    state = state.copyWith(timeUp: true, remaining: Duration.zero);
    unawaited(_submit());
  }

  /// A chosen option. Choice questions travel as a **list** of option ids, which is what
  /// `QuizAnswers` means by "option ids for choice questions" (progress.md finding 12).
  void answerOne(String questionId, String optionId) =>
      _write(questionId, optionId.isEmpty ? const <String>[] : [optionId]);

  /// Multiple-choice: the whole selection, as the card hands it back.
  void answerMany(String questionId, List<String> optionIds) => _write(questionId, optionIds);

  /// A typed answer. Only short-answer questions send a string.
  void writeAnswer(String questionId, String text) => _write(questionId, text);

  void _write(String questionId, Object answer) {
    final session = state.session;
    if (state.locked || session == null || !session.isActive) return;
    if (state.phase != QuizPhase.answering && state.phase != QuizPhase.review) return;
    _version++;
    _sheet = {...state.answers, questionId: answer};
    state = state.copyWith(
      answers: _sheet,
      save: _saveInFlight ? QuizSaveStatus.saving : QuizSaveStatus.unsaved,
      saveFailure: null,
    );
    _debounce?.cancel();
    _retry?.cancel();
    _debounce = Timer(_timings.saveDelay, () => unawaited(flush()));
  }

  /// Sends the sheet now if anything is unsaved — when the app goes to the background, when the
  /// network comes back, or when the learner asks to try again.
  Future<void> flush() async {
    final session = state.session;
    if (_disposed || session == null || !session.isActive || _handedIn) return;
    // Time is up and the hand-in has not gone through: it is what is waiting, so send it now
    // rather than at its next retry. Cancelling that retry without sending it here would leave
    // the attempt handed in by nobody but the server.
    if (state.timeUp) {
      if (!_handingIn) {
        _retry?.cancel();
        unawaited(_submit());
      }
      return;
    }
    if (_handingIn) return;
    _debounce?.cancel();
    _retry?.cancel();
    if (!_dirty || _saveInFlight) return;
    final seq = ++_seq;
    final version = _version;
    final sheet = Map<String, Object>.of(state.answers);
    _saveInFlight = true;
    state = state.copyWith(save: QuizSaveStatus.saving);
    try {
      final stored = await _api.saveAnswers(
        courseId: target.courseId,
        lessonId: target.lessonId,
        sessionId: session.id,
        answers: sheet,
        seq: seq,
      );
      _saveInFlight = false;
      if (_disposed || _handedIn || state.session?.id != session.id) return;
      _saveFailures = 0;
      _sync(stored);
      if (stored.answersSeq == seq) {
        // Kept. A response that arrives after a newer sheet was confirmed changes nothing.
        if (seq > _confirmedSeq) {
          _confirmedSeq = seq;
          _confirmedVersion = version;
          state = state.copyWith(savedAnswers: stored.answerSheet, savedAt: stored.savedAt);
        }
      } else if (stored.answersSeq > _seq) {
        // The server already holds a higher number (another device): this sheet was ignored, so
        // it goes again above it.
        _seq = stored.answersSeq;
      }
      _afterSave();
    } on ApiException catch (e) {
      _saveInFlight = false;
      if (_disposed || _handedIn) return;
      _saveFailed(e.failure);
    }
  }

  void _afterSave() {
    if (_dirty) {
      if (_debounce?.isActive ?? false) {
        state = state.copyWith(save: QuizSaveStatus.unsaved);
      } else {
        unawaited(flush());
      }
      return;
    }
    state = state.copyWith(save: QuizSaveStatus.saved, saveFailure: null);
    tick();
  }

  void _saveFailed(AppFailure failure) {
    if (failure is QuizSessionFailure && failure.attemptOver) {
      // The server has closed the attempt: nothing more is saved, and its result is what is left.
      _ticker?.cancel();
      state = state.copyWith(timeUp: true, remaining: state.isTimed ? Duration.zero : null);
      unawaited(_submit());
      return;
    }
    if (failure case NetworkFailure(problem: NetworkProblem.cancelled)) return;
    if (_isTransient(failure) && _saveFailures < _timings.retryDelays.length) {
      final wait = _timings.retryDelays[_saveFailures];
      _saveFailures++;
      state = state.copyWith(save: QuizSaveStatus.retrying, saveFailure: failure);
      _retry = Timer(wait, () => unawaited(flush()));
      return;
    }
    state = state.copyWith(save: QuizSaveStatus.failed, saveFailure: failure);
  }

  /// The learner's "Try again" on a save that stopped.
  Future<void> retrySave() {
    _saveFailures = 0;
    return flush();
  }

  void goTo(int index) {
    if (index < 0 || index >= state.questions.length) return;
    if (state.phase != QuizPhase.answering && state.phase != QuizPhase.review) return;
    state = state.copyWith(index: index, phase: QuizPhase.answering);
  }

  void next() => goTo(state.index + 1);

  void previous() => goTo(state.index - 1);

  /// The last look before handing in.
  void review() {
    if (state.phase != QuizPhase.answering) return;
    state = state.copyWith(phase: QuizPhase.review);
  }

  /// Hands the attempt in with the sheet as it stands. Safe to repeat: the server answers with the
  /// same result, and this screen shows one result only.
  Future<void> submit() => _submit();

  Future<void> _submit() async {
    final session = state.session;
    if (_handingIn || _handedIn || session == null) return;
    _handingIn = true;
    _debounce?.cancel();
    _retry?.cancel();
    final sheet = Map<String, Object>.of(state.answers);
    final seq = ++_seq;
    state = state.copyWith(phase: QuizPhase.submitting, failure: null, refusal: null);
    try {
      final handedIn = await _api.submit(
        courseId: target.courseId,
        lessonId: target.lessonId,
        sessionId: session.id,
        answers: sheet,
        seq: seq,
      );
      _handingIn = false;
      if (_disposed) return;
      _finish(handedIn);
    } on ApiException catch (e) {
      _handingIn = false;
      if (_disposed || _handedIn) return;
      final failure = e.failure;
      if (_isTransient(failure)) {
        if (state.timeUp) {
          // Time is up and the server finishes the attempt anyway; keep asking for its result.
          final delays = _timings.retryDelays;
          final wait = delays[min(_handInFailures, delays.length - 1)];
          _handInFailures++;
          state = state.copyWith(failure: failure);
          _retry = Timer(wait, () => unawaited(_submit()));
        } else {
          state = state.copyWith(phase: QuizPhase.review, failure: failure);
          // What did not go with the hand-in is saved as usual meanwhile.
          if (_dirty) _debounce = Timer(_timings.saveDelay, () => unawaited(flush()));
        }
        return;
      }
      state = state.copyWith(
        phase: state.timeUp ? QuizPhase.submitting : QuizPhase.review,
        refusal: failure is ConflictFailure ? failure.message : null,
        failure: failure is ConflictFailure ? null : failure,
      );
    }
  }

  void _finish(QuizHandIn handedIn) {
    _handedIn = true;
    _ticker?.cancel();
    _retry?.cancel();
    _debounce?.cancel();
    _confirmedVersion = _version;
    final review = handedIn.review;
    state = state.copyWith(
      phase: QuizPhase.result,
      session: handedIn.session,
      standing: handedIn.standing,
      history: review == null
          ? state.history
          : [review, ...state.history.where((a) => a.attemptId != review.attemptId)],
      result: review,
      completion: handedIn.completion,
      expired: handedIn.session.status == QuizSessionStatus.expired || (review?.expired ?? false),
      savedAnswers: handedIn.session.answerSheet,
      save: QuizSaveStatus.idle,
      saveFailure: null,
      remaining: null,
      failure: null,
      refusal: null,
    );
    _refreshWorkspace();
  }

  /// An attempt the server finished while this screen was away: its result, from the history.
  Future<void> _showFinished(QuizSessionView session) async {
    _handedIn = true;
    _ticker?.cancel();
    _debounce?.cancel();
    _retry?.cancel();
    state = state.copyWith(
      phase: QuizPhase.result,
      session: session,
      expired: session.status == QuizSessionStatus.expired,
      remaining: null,
      save: QuizSaveStatus.idle,
    );
    try {
      final read = await _api.attempts(courseId: target.courseId, lessonId: target.lessonId);
      if (_disposed) return;
      final review =
          read.attempts.where((a) => a.attemptId == session.attemptId).firstOrNull ??
          read.attempts.firstOrNull;
      state = state.copyWith(
        standing: read.standing,
        history: read.attempts,
        result: review,
        expired: state.expired || (review?.expired ?? false),
        failure: null,
      );
      _refreshWorkspace();
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(failure: e.failure);
    }
  }

  /// The result's history could not be read: read it again.
  Future<void> reloadResult() async {
    final session = state.session;
    if (session == null || state.phase != QuizPhase.result) return;
    await _showFinished(session);
  }

  /// The app is back in front: the server's time and answers are read again, because the phone
  /// may have slept, been offline or been used on another device meanwhile.
  Future<void> onAppResumed() async {
    final session = state.session;
    if (_disposed || session == null || !state.inAttempt || _handingIn || _handedIn) return;
    try {
      final latest = await _api.latestSession(courseId: target.courseId, lessonId: target.lessonId);
      if (_disposed || _handingIn || _handedIn) return;
      if (latest == null) {
        await load();
        return;
      }
      final stored = latest.session;
      if (stored.id != session.id || !stored.isActive) {
        await _showFinished(stored);
        return;
      }
      _sync(stored, force: true);
      if (stored.answersSeq > _seq) _seq = stored.answersSeq;
      if (_dirty) {
        // This phone has answers the server has not got: they go now, numbered above its own.
        state = state.copyWith(session: stored);
        unawaited(flush());
      } else {
        _confirmedSeq = stored.answersSeq;
        _sheet = stored.answerSheet;
        state = state.copyWith(
          session: stored,
          answers: stored.answerSheet,
          savedAnswers: stored.answerSheet,
          questions: state.questions.isEmpty ? latest.questions : null,
          savedAt: stored.savedAt,
          save: stored.savedAt == null ? state.save : QuizSaveStatus.saved,
        );
      }
      tick();
    } on ApiException {
      // The countdown keeps going on this phone's clock; the next answer from the server resyncs it.
      tick();
    }
  }

  /// The app is going to the background: what is unsaved goes now.
  void onAppPaused() => unawaited(flush());

  /// Back to the introduction for another attempt, when the server allows one.
  void retake() {
    if (!(state.standing?.canStart ?? false)) return;
    _handedIn = false;
    state = QuizTakerState(
      phase: QuizPhase.intro,
      quiz: state.quiz,
      standing: state.standing,
      history: state.history,
    );
  }

  void clearRefusal() => state = state.copyWith(refusal: null, opensAt: null, failure: null);

  Future<void> _refreshStanding() async {
    try {
      final read = await _api.attempts(courseId: target.courseId, lessonId: target.lessonId);
      if (_disposed || state.inAttempt) return;
      state = state.copyWith(standing: read.standing, history: read.attempts);
    } on ApiException {
      // The refusal already says why; the standing is read again on the next visit.
    }
  }

  static bool _isTransient(AppFailure failure) => switch (failure) {
    NetworkFailure(problem: NetworkProblem.cancelled) => false,
    NetworkFailure() || ServerFailure() || RateLimitedFailure() => true,
    _ => false,
  };

  /// 128 random bits, as hex: a retried start answers with the same session.
  @visibleForTesting
  static String newStartKey() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Handing in can complete a lesson, a chapter and a course.
  void _refreshWorkspace() {
    ref.invalidate(assessmentsProvider);
    ref.invalidate(learnerHomeProvider);
    ref.invalidate(learnerCoursesProvider);
  }
}

final quizTakerProvider = NotifierProvider.family<QuizTakerController, QuizTakerState, QuizRef>(
  QuizTakerController.new,
  isAutoDispose: true,
);
