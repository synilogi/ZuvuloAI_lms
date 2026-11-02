import '../../../core/errors/app_failure.dart';
import '../../../l10n/l10n.dart';
import '../application/auth_form.dart';

/// Turns a refusal into what an auth screen says: the app's own title, with the server's message
/// as the detail when it wrote one for people (§16). The full refusal mapping for the rest of the
/// app is FLUTTER-006's.
({String title, String? detail}) authFailureText(AppLocalizations l10n, AppFailure failure) {
  return switch (failure) {
    // The platform suspended or closed the Admin's LMS (403 ACADEMY_SUSPENDED / ACADEMY_ARCHIVED).
    AccountClosedFailure(:final archived) => (
      title: archived ? l10n.accountClosedTitle : l10n.accountSuspendedTitle,
      detail: failure.message,
    ),
    // 403 INVITATION_REQUIRED: the LMS adds learners by invitation only.
    InvitationRequiredFailure() => (title: l10n.invitationRequiredTitle, detail: failure.message),
    // A self-registered instructor the LMS admin has not approved, or refused (D34).
    InstructorApprovalFailure(:final rejected) => (
      title: rejected ? l10n.instructorRejectedTitle : l10n.instructorPendingTitle,
      detail: failure.message,
    ),
    // 404 on register: no LMS has the address that was entered.
    NotFoundFailure() => (title: l10n.registerWorkspaceNotFound, detail: failure.message),
    NetworkFailure() => (title: l10n.stateErrorTitle, detail: l10n.offlineActionDisabled),
    // 403 LIMIT_REACHED on register: the academy is full.
    EntitlementFailure() => (title: l10n.registerLimitReached, detail: failure.message),
    ValidationFailure() => (title: l10n.stateErrorTitle, detail: failure.message),
    ConflictFailure() => (title: l10n.stateErrorTitle, detail: failure.message),
    RateLimitedFailure() => (title: l10n.stateErrorTitle, detail: failure.message),
    _ => (title: l10n.stateErrorTitle, detail: failure.message),
  };
}

/// Client-side validators mirroring the route's zod schema — UX only; the server re-checks (§16).
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(AppLocalizations l10n, String? value) =>
      _email.hasMatch((value ?? '').trim()) ? null : l10n.validationEmail;

  static String? loginPassword(AppLocalizations l10n, String? value) =>
      (value ?? '').isEmpty ? l10n.validationPasswordRequired : null;

  static String? newPassword(AppLocalizations l10n, String? value) =>
      (value ?? '').length < 8 ? l10n.validationPasswordMin : null;

  /// An LMS address, as the server's own rule has it: lowercase letters, digits and single hyphens,
  /// 3–40 characters. [workspaceFrom] turns a pasted join link into one first.
  static final _workspace = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  static String? workspace(AppLocalizations l10n, String? value) {
    final slug = workspaceFrom(value ?? '');
    return slug.length >= 3 && slug.length <= 40 && _workspace.hasMatch(slug)
        ? null
        : l10n.validationWorkspace;
  }

  /// The address from what was typed or pasted: the part after `join` in a join link
  /// (`https://…/join/saraswati-coaching`, or its `…/teach` form for instructors), else the last part
  /// of the text, or the address itself — lower-cased.
  static String workspaceFrom(String raw) {
    final segments = raw.trim().split('/').where((s) => s.isNotEmpty).toList();
    final join = segments.indexOf('join');
    if (join >= 0 && join + 1 < segments.length) return segments[join + 1].toLowerCase();
    return (segments.isEmpty ? '' : segments.last).toLowerCase();
  }

  static String? name(AppLocalizations l10n, String? value) =>
      (value ?? '').trim().length < 2 ? l10n.validationNameMin : null;

  static String? confirmPassword(AppLocalizations l10n, String? value, String password) =>
      value == password ? null : l10n.validationPasswordsMatch;
}
