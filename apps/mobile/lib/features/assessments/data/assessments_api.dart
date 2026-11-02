import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/quiz.dart';
import 'dto/assessment_row.dart';
import 'dto/quiz_attempt.dart';

/// `apps/api/src/routes/learning.ts` — the learner's quizzes. A quiz is taken through a session the
/// server starts, times and finishes: the questions come with it, every save carries the whole
/// answer sheet with a number that only grows, and the server scores what it accepted before its
/// deadline (§18, §28.4). Nothing here marks an answer or measures time.
class AssessmentsApi {
  AssessmentsApi(this._client);

  final ApiClient _client;

  Future<List<AssessmentRow>> assessments() async {
    const endpoint = 'GET /learning/assessments';
    final body = await _client.get('/learning/assessments');
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b))
          AssessmentRow.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  /// Starts the learner's next attempt — or picks up the one still open — and only now receives
  /// its questions. Starting uses an attempt. [startKey] makes a retried start answer with the
  /// session the first one made: one per tap, reused when that tap's request is sent again.
  Future<QuizSessionStart> startSession({
    required String courseId,
    required String lessonId,
    String? startKey,
  }) async {
    const endpoint = 'POST $_sessionPattern';
    final body = await _client.post(_session(courseId, lessonId), body: {'startKey': ?startKey});
    return parseResponse(
      endpoint,
      body,
      (b) => QuizSessionStart.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The learner's latest attempt: the open one with its questions, a finished one without, or
  /// `null` when there has been none. Reading it starts nothing — it is how an attempt is picked
  /// up after the app was closed, and how its time and answers are put right again.
  Future<QuizSessionStart?> latestSession({
    required String courseId,
    required String lessonId,
  }) async {
    const endpoint = 'GET $_sessionPattern';
    final body = await _client.get(_session(courseId, lessonId));
    return parseResponse(endpoint, body, (b) {
      final json = asJsonObject(endpoint, b);
      if (json['session'] == null) return null;
      return QuizSessionStart.fromJson({...json, 'resumed': true});
    });
  }

  /// Autosave: the learner's whole answer sheet, numbered [seq]. The server keeps it only before
  /// its deadline, and a sheet numbered no higher than the stored one changes nothing — the stored
  /// session comes back either way, so its `answersSeq` says whether this one was kept.
  ///
  /// [answers] maps a question id to the chosen option ids or the typed answer — never a score.
  Future<QuizSessionView> saveAnswers({
    required String courseId,
    required String lessonId,
    required String sessionId,
    required Map<String, Object> answers,
    required int seq,
  }) async {
    const endpoint = 'PUT $_sessionPattern/:sessionId/answers';
    final body = await _client.put(
      _session(courseId, lessonId, [ApiPath.id(sessionId), 'answers']),
      body: {'answers': answers, 'seq': seq},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => QuizSessionView.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Hands the attempt in, with a final sheet the server takes only before its deadline. Safe to
  /// repeat: a finished attempt answers with the same result again.
  Future<QuizHandIn> submit({
    required String courseId,
    required String lessonId,
    required String sessionId,
    Map<String, Object>? answers,
    int? seq,
  }) async {
    const endpoint = 'POST $_sessionPattern/:sessionId/submit';
    final body = await _client.post(
      _session(courseId, lessonId, [ApiPath.id(sessionId), 'submit']),
      body: answers != null && seq != null
          ? {'answers': answers, 'seq': seq}
          : const <String, Object>{},
    );
    return parseResponse(endpoint, body, (b) => QuizHandIn.fromJson(asJsonObject(endpoint, b)));
  }

  /// The learner's attempts at the lesson's quiz, newest first and cut to what they may see, and
  /// where they stand: attempts used and allowed, the window, an attempt open to resume.
  Future<QuizAttempts> attempts({required String courseId, required String lessonId}) async {
    const endpoint = 'GET /learning/courses/:courseId/lessons/:lessonId/quiz-attempts';
    final body = await _client.get(
      ApiPath.of([
        'learning',
        'courses',
        ApiPath.id(courseId),
        'lessons',
        ApiPath.id(lessonId),
        'quiz-attempts',
      ]),
    );
    return parseResponse(endpoint, body, (b) => QuizAttempts.fromJson(asJsonObject(endpoint, b)));
  }

  static const _sessionPattern = '/learning/courses/:courseId/lessons/:lessonId/quiz-session';

  static String _session(String courseId, String lessonId, [List<Object> rest = const []]) =>
      ApiPath.of([
        'learning',
        'courses',
        ApiPath.id(courseId),
        'lessons',
        ApiPath.id(lessonId),
        'quiz-session',
        ...rest,
      ]);
}

final assessmentsApiProvider = Provider<AssessmentsApi>(
  (ref) => AssessmentsApi(ref.watch(apiClientProvider)),
);
