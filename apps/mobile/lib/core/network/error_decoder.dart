import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/app_failure.dart';

/// Turns a failed exchange into an [AppFailure] exactly as modules.md §10.3 tabulates, reading the
/// backend's error body `{message, issues?, code?}` (`apps/api/src/lib/errors.ts`). Unknown codes
/// fall back by HTTP status.
abstract final class ErrorDecoder {
  /// The server's generic 500 text — not worth showing as a detail line.
  static const _genericServerMessage = 'Something went wrong.';

  static AppFailure fromDioException(DioException e) {
    final response = e.response;
    if (response != null) return fromResponse(response.statusCode ?? 0, response.data);
    return NetworkFailure(switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => NetworkProblem.timeout,
      DioExceptionType.badCertificate => NetworkProblem.tls,
      DioExceptionType.cancel => NetworkProblem.cancelled,
      DioExceptionType.connectionError => _connectionProblem(e.error),
      DioExceptionType.badResponse || DioExceptionType.unknown => _connectionProblem(e.error),
    });
  }

  static NetworkProblem _connectionProblem(Object? error) {
    if (error is HandshakeException || error is TlsException) return NetworkProblem.tls;
    if (error is SocketException) {
      final text = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
      if (text.contains('host lookup') || text.contains('no address associated')) {
        return NetworkProblem.dns;
      }
      return NetworkProblem.offline;
    }
    return error == null ? NetworkProblem.offline : NetworkProblem.unknown;
  }

  static AppFailure fromResponse(int status, Object? body) {
    final map = body is Map ? body : const <Object?, Object?>{};
    final message = map['message'] is String ? map['message']! as String : null;
    final code = map['code'] is String ? map['code']! as String : null;
    final issues = _issues(map['issues']);

    switch (status) {
      case 400:
        // A course payment whose signature did not verify: nothing opened, and the server says why.
        if (code == 'PAYMENT_FAILED') return PaymentFailure(message: message);
        return ValidationFailure(message: message, issues: issues);
      case 401:
        return UnauthenticatedFailure(message: message);
      case 402:
        return EntitlementFailure(switch (code) {
          'SUBSCRIPTION_EXPIRED' => EntitlementProblem.subscriptionExpired,
          'SUBSCRIPTION_PAST_DUE' => EntitlementProblem.subscriptionPastDue,
          _ => EntitlementProblem.subscriptionRequired,
        }, message: message);
      case 403:
        return switch (code) {
          'PERMISSION_DENIED' => PermissionFailure(message: message),
          'ACADEMY_SUSPENDED' => AccountClosedFailure(archived: false, message: message),
          'ACADEMY_ARCHIVED' => AccountClosedFailure(archived: true, message: message),
          'INSTRUCTOR_PENDING' => InstructorApprovalFailure(rejected: false, message: message),
          'INSTRUCTOR_REJECTED' => InstructorApprovalFailure(rejected: true, message: message),
          'FEATURE_NOT_INCLUDED' => EntitlementFailure(
            EntitlementProblem.featureNotIncluded,
            message: message,
          ),
          'LIMIT_REACHED' => EntitlementFailure(EntitlementProblem.limitReached, message: message),
          'INVITATION_REQUIRED' => InvitationRequiredFailure(message: message),
          'SUBSCRIPTION_PAST_DUE' => EntitlementFailure(
            EntitlementProblem.subscriptionPastDue,
            message: message,
          ),
          _ => ForbiddenFailure(message: message),
        };
      case 404:
        return NotFoundFailure(message: message);
      case 409:
        final sale = CourseSaleProblem.fromCode(code);
        if (sale != null) return CourseSaleFailure(sale, code: code, message: message);
        final enrolment = EnrollmentProblem.fromCode(code);
        if (enrolment != null) {
          return EnrollmentFailure(enrolment, code: code, message: message);
        }
        final quiz = QuizSessionProblem.fromCode(code);
        if (quiz != null) {
          final detail = map['issues'] is Map ? map['issues']! as Map : const <Object?, Object?>{};
          return QuizSessionFailure(
            quiz,
            code: code,
            message: message,
            opensAt: _instant(detail['opensAt']),
            closesAt: _instant(detail['closesAt']),
          );
        }
        return ConflictFailure(
          code: code,
          message: message,
          issues: issues,
          rawIssues: map['issues'] is List ? map['issues']! as List<Object?> : const [],
        );
      case 413:
        return PayloadTooLargeFailure(message: message);
      case 429:
        return RateLimitedFailure(message: message);
    }
    if (status == 502 && code == 'PAYMENT_FAILED') return PaymentFailure(message: message);
    if (status >= 500) {
      return ServerFailure(
        status: status,
        message: message == _genericServerMessage ? null : message,
      );
    }
    // Any other client error (415, 422…): a request the server could not accept.
    return ValidationFailure(message: message, issues: issues);
  }

  static DateTime? _instant(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  /// `issues` arrives as `[{path, message}]` (400, zod) or `[{field, message}]` (409 domain
  /// checklists); anything else is ignored rather than guessed at.
  static List<FieldIssue> _issues(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map && item['message'] is String)
          FieldIssue(
            message: item['message']! as String,
            path: item['path'] is String ? item['path']! as String : null,
            field: item['field'] is String ? item['field']! as String : null,
            criterionId: item['criterionId'] is String ? item['criterionId']! as String : null,
          ),
    ];
  }
}

/// 403 `INVITATION_REQUIRED`: the LMS adds learners by invitation only, so a join link or a course link
/// is no way in for a new learner — an invitation is. A [ForbiddenFailure], so every existing switch
/// still treats it as a refusal; the registration screens name it.
class InvitationRequiredFailure extends ForbiddenFailure {
  const InvitationRequiredFailure({super.message});
}

/// Why a course could not be joined or bought, as the 409's `code` says (`apps/api/src/lib/errors.ts`).
enum CourseSaleProblem {
  /// `COURSE_PURCHASE_REQUIRED`: a paid course is joined by buying it, never by Enrol.
  purchaseRequired('COURSE_PURCHASE_REQUIRED'),

  /// `COURSE_NOT_FOR_SALE`: the academy has not decided the price, or the course is not open.
  notForSale('COURSE_NOT_FOR_SALE'),

  /// `PAYMENTS_NOT_SET_UP`: the academy takes no online payments yet.
  paymentsNotSetUp('PAYMENTS_NOT_SET_UP'),

  /// `ALREADY_ENROLLED`: the learner has the course already; there is nothing to buy.
  alreadyEnrolled('ALREADY_ENROLLED');

  const CourseSaleProblem(this.code);

  final String code;

  static CourseSaleProblem? fromCode(String? code) {
    for (final problem in values) {
      if (problem.code == code) return problem;
    }
    return null;
  }
}

/// 409 with one of the [CourseSaleProblem] codes. A [ConflictFailure] with its `code` kept, so every
/// existing switch still treats it as a refusal; the course page names it.
class CourseSaleFailure extends ConflictFailure {
  const CourseSaleFailure(this.problem, {super.code, super.message});

  final CourseSaleProblem problem;
}

/// Why the server refused a quiz attempt or one of its saves, as the 409's `code` says
/// (`apps/api/src/lib/quizSessions.ts`).
enum QuizSessionProblem {
  /// `QUIZ_TIME_UP`: the deadline has passed — answers sent now are not counted.
  timeUp('QUIZ_TIME_UP'),

  /// `QUIZ_FINISHED`: the attempt has already been handed in.
  finished('QUIZ_FINISHED'),

  /// `TEST_NOT_OPEN`: the quiz opens later ([QuizSessionFailure.opensAt]).
  notOpen('TEST_NOT_OPEN'),

  /// `TEST_CLOSED`: the quiz has closed.
  closed('TEST_CLOSED'),

  /// `QUIZ_SESSION_REQUIRED`: the quiz is timed on the server, so the one-request attempt of old
  /// apps is refused.
  sessionRequired('QUIZ_SESSION_REQUIRED');

  const QuizSessionProblem(this.code);

  final String code;

  static QuizSessionProblem? fromCode(String? code) {
    for (final problem in values) {
      if (problem.code == code) return problem;
    }
    return null;
  }
}

/// 409 with one of the [QuizSessionProblem] codes. A [ConflictFailure] with its `code` and the
/// server's message kept, so every existing switch still treats it as a refusal.
class QuizSessionFailure extends ConflictFailure {
  const QuizSessionFailure(this.problem, {super.code, super.message, this.opensAt, this.closesAt});

  final QuizSessionProblem problem;

  /// When the quiz opens, for [QuizSessionProblem.notOpen].
  final DateTime? opensAt;

  /// When it closed, for [QuizSessionProblem.closed].
  final DateTime? closesAt;

  /// The attempt is over on the server: stop saving and show its result.
  bool get attemptOver =>
      problem == QuizSessionProblem.timeUp || problem == QuizSessionProblem.finished;
}

/// Why the learner's enrolment refused the action, as the 409's `code` says: access to the course
/// is paused, or has ended. The server's message says it in the academy's words.
enum EnrollmentProblem {
  /// `ENROLLMENT_PAUSED`
  paused('ENROLLMENT_PAUSED'),

  /// `ENROLLMENT_EXPIRED`
  expired('ENROLLMENT_EXPIRED');

  const EnrollmentProblem(this.code);

  final String code;

  static EnrollmentProblem? fromCode(String? code) {
    for (final problem in values) {
      if (problem.code == code) return problem;
    }
    return null;
  }
}

/// 409 with one of the [EnrollmentProblem] codes. A [ConflictFailure] with its `code` and message
/// kept, so every existing switch still treats it as a refusal to show.
class EnrollmentFailure extends ConflictFailure {
  const EnrollmentFailure(this.problem, {super.code, super.message});

  final EnrollmentProblem problem;
}
