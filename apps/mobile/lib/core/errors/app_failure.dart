/// Every way a request can fail, as the app handles it (modules.md §10.3). The API client's
/// decoder (FLUTTER-003) produces these; controllers and widgets switch on them exhaustively.
/// `message` is the server's human-readable text where it sent one — shown as a detail line under
/// the app's own copy, never as the only explanation.
sealed class AppFailure {
  const AppFailure({this.message});

  final String? message;
}

/// One field-level problem. 400 validation issues carry a `path`; 409 domain checklists carry a
/// `field`. [key] is whichever the server sent, for mapping onto a form field.
class FieldIssue {
  const FieldIssue({required this.message, this.path, this.field, this.criterionId});

  final String? path;
  final String? field;

  /// Which line of a list the problem belongs to, where the field is a list — a review's
  /// `scores` names the rubric criterion it refused (`ReviewIssue`), and without it a screen could
  /// only say "one of these" (finding 26).
  final String? criterionId;
  final String message;

  String? get key => path ?? field;

  /// Whether this problem is the one for [field], and for [criterionId] when the field is a list.
  bool isAbout(String field, {String? criterionId}) =>
      key == field && (criterionId == null || this.criterionId == criterionId);

  @override
  bool operator ==(Object other) =>
      other is FieldIssue &&
      other.path == path &&
      other.field == field &&
      other.criterionId == criterionId &&
      other.message == message;

  @override
  int get hashCode => Object.hash(path, field, criterionId, message);
}

/// [cancelled]: the request was abandoned (screen closed, session ended) — callers stay quiet.
enum NetworkProblem { offline, timeout, dns, tls, cancelled, unknown }

/// No response: offline, timed out, DNS or TLS failure.
class NetworkFailure extends AppFailure {
  const NetworkFailure(this.problem);

  final NetworkProblem problem;
}

/// 400 — the request did not pass the route's schema.
class ValidationFailure extends AppFailure {
  const ValidationFailure({super.message, this.issues = const []});

  final List<FieldIssue> issues;
}

/// 401 — no valid session; triggers the single sign-out path (§6).
class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure({super.message});
}

/// `SUBSCRIPTION_PAST_DUE` is a declared stable code the server does not issue yet; it is decoded
/// defensively so a future server does not fall through to a generic refusal.
enum EntitlementProblem {
  subscriptionRequired,
  subscriptionPastDue,
  subscriptionExpired,
  featureNotIncluded,
  limitReached,
}

/// 402 `SUBSCRIPTION_REQUIRED`/`SUBSCRIPTION_EXPIRED`, 403 `FEATURE_NOT_INCLUDED`/`LIMIT_REACHED`.
/// No machine field names the feature or limit — only [message] does (§9).
class EntitlementFailure extends AppFailure {
  const EntitlementFailure(this.problem, {super.message});

  final EntitlementProblem problem;
}

/// 403 `PERMISSION_DENIED` — the admin lacks the permission key.
class PermissionFailure extends AppFailure {
  const PermissionFailure({super.message});
}

/// 403 without a code: role refusals, suspended/deactivated accounts, review-before-publish.
class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.message});
}

/// 403 `ACADEMY_SUSPENDED` / `ACADEMY_ARCHIVED`: the platform suspended or closed the Admin's whole
/// LMS, so nobody in it can act until it is restored. A [ForbiddenFailure], so every existing switch
/// still treats it as a refusal; the session ends on it and the sign-in screen says why.
class AccountClosedFailure extends ForbiddenFailure {
  const AccountClosedFailure({required this.archived, super.message});

  /// Closed for good (archived) rather than suspended.
  final bool archived;
}

/// 403 `INSTRUCTOR_PENDING` / `INSTRUCTOR_REJECTED`: an instructor who registered themselves and
/// is waiting for the LMS admin's approval, or was refused it (D34). Only told once the password
/// matched; the server's message says which.
class InstructorApprovalFailure extends ForbiddenFailure {
  const InstructorApprovalFailure({required this.rejected, super.message});

  /// Refused by the admin, rather than still waiting.
  final bool rejected;
}

/// 404 — missing, or out of the caller's scope (never distinguished, §7).
class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.message});
}

/// 409 — a state conflict or a domain checklist (`PLAN_UNAVAILABLE`, `PAYMENT_REQUIRED`,
/// `INVALID_SUBSCRIPTION_STATE`, `CONFLICT`, or none).
class ConflictFailure extends AppFailure {
  const ConflictFailure({
    this.code,
    super.message,
    this.issues = const [],
    this.rawIssues = const [],
  });

  final String? code;
  final List<FieldIssue> issues;

  /// The `issues` array exactly as the route sent it. Most refusals are `{field, message}` pairs,
  /// which [issues] already reads; a few carry a domain shape of their own — the publish checklist
  /// is `{id, label, met}` — and the feature that knows that shape reads it from here.
  final List<Object?> rawIssues;
}

/// 413 — the upload is larger than the server accepts.
class PayloadTooLargeFailure extends AppFailure {
  const PayloadTooLargeFailure({super.message});
}

/// 429 — too many attempts; never retried automatically for writes.
class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({super.message});
}

/// 502 `PAYMENT_FAILED` — the payment provider refused.
class PaymentFailure extends AppFailure {
  const PaymentFailure({super.message});
}

/// Any other 5xx.
class ServerFailure extends AppFailure {
  const ServerFailure({required this.status, super.message});

  final int status;
}

/// A response the app could not read — the model is wrong and must be fixed against the backend.
class ContractFailure extends AppFailure {
  const ContractFailure({required this.endpoint, required this.detail});

  final String endpoint;

  /// What failed to parse (field path/type) — never the body.
  final String detail;
}
