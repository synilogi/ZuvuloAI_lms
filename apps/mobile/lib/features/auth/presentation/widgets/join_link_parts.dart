import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/route_access.dart';
import '../../../../app/routing/routes.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../../application/session_controller.dart';
import '../auth_messages.dart';
import 'auth_scaffold.dart';

/// The pieces the link screens share — an invitation, a course link and a join link all open the
/// same way: read what the link names, then either explain why it cannot be used or offer a form.

/// A link that names nothing usable (invalid, expired, unknown course, LMS closed): what happened,
/// and the way back to the start. Nothing on it can be submitted.
class JoinLinkProblem extends StatelessWidget {
  const JoinLinkProblem({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: title,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(body, style: context.type.bodyM.copyWith(color: context.colors.muted)),
        ),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.actionBack,
          variant: AppButtonVariant.secondary,
          expand: true,
          // A link usually opens the app on this screen, with nothing beneath it to pop back to.
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).popUntil((route) => route.isFirst)
              : GoRouter.of(context).go(AppRoutes.welcome),
        ),
      ],
    );
  }
}

/// The link could not be read for another reason (offline, server down): say so and offer Retry.
class JoinLinkUnreachable extends StatelessWidget {
  const JoinLinkUnreachable({required this.failure, required this.onRetry, super.key});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = authFailureText(l10n, failure);
    return AuthScaffold(
      title: l10n.stateErrorTitle,
      children: [
        AuthErrorBanner(title: text.title, detail: text.detail),
        const SizedBox(height: Space.s4),
        AppButton(label: l10n.actionRetry, expand: true, onPressed: onRetry),
      ],
    );
  }
}

/// Someone is already signed in on this device when a link arrives. A link is never attached to
/// the session that happens to be open — it would join, or enrol, whoever last used the phone — so
/// the only ways on are signing out first or leaving the link alone.
class JoinLinkSignedIn extends ConsumerWidget {
  const JoinLinkSignedIn({required this.title, required this.profile, super.key, this.body});

  final String title;
  final UserProfile profile;

  /// What signing out lets them do; defaults to the general explanation.
  final String? body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: title,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.joinSignedInTitle(profile.name), style: context.type.titleS),
              const SizedBox(height: Space.s2),
              Text(
                body ?? l10n.joinSignedInBody,
                style: context.type.bodyM.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.actionSignOutAndContinue,
          expand: true,
          // Signing out stays on this screen: the link is public, and the form takes over.
          onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
        ),
        const SizedBox(height: Space.s3),
        AppButton(
          label: l10n.actionGoHome,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => GoRouter.of(context).go(homeFor(profile.role)),
        ),
      ],
    );
  }
}

/// Draws a link's lookup: a spinner while it is read, [problem] for a 404, Retry for anything else,
/// and [data] once it is known.
Widget joinLinkLookup<T>({
  required AsyncValue<AppResult<T>> lookup,
  required Widget Function() notFound,
  required VoidCallback onRetry,
  required Widget Function(T value) data,
}) {
  return lookup.when(
    loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    error: (_, _) => notFound(),
    data: (result) => switch (result) {
      Err(failure: NotFoundFailure()) => notFound(),
      Err(:final failure) => JoinLinkUnreachable(failure: failure, onRetry: onRetry),
      Ok(:final value) => data(value),
    },
  );
}

/// A refusal on one of the link forms, in the app's words, with the server's as the detail (§16).
/// [signingIn] is the "I already have an account" path: there a 409 means the account belongs to
/// another LMS, and a suspended LMS is the account's own. [notFoundTitle] names what the link was.
({String title, String? detail}) joinFailureText(
  AppLocalizations l10n,
  AppFailure failure, {
  required String notFoundTitle,
  bool signingIn = false,
}) {
  final detail = failure.message;
  return switch (failure) {
    NotFoundFailure() => (title: notFoundTitle, detail: detail),
    AccountClosedFailure() when signingIn => authFailureText(l10n, failure),
    // 403 ACADEMY_SUSPENDED on a new account: the LMS takes nobody new.
    AccountClosedFailure() => (title: l10n.joinLmsClosedTitle, detail: detail),
    // 403 INVITATION_REQUIRED: a course link (or join link) into an LMS that adds learners by
    // invitation only.
    InvitationRequiredFailure() => (title: l10n.invitationRequiredTitle, detail: detail),
    // 403 without a code: an invitation bound to another address, or a deactivated account.
    ForbiddenFailure() when signingIn => (title: l10n.loginFailedTitle, detail: detail),
    ForbiddenFailure() => (title: l10n.inviteWrongEmailTitle, detail: detail),
    // 409: on sign-in the account belongs to another LMS (or is staff); on create, the email is taken.
    ConflictFailure() when signingIn => (title: l10n.joinOtherLmsTitle, detail: detail),
    ConflictFailure() => (title: l10n.registerFailedTitle, detail: detail),
    // LIMIT_REACHED and friends: the LMS is full, or its plan has ended.
    EntitlementFailure() => (title: l10n.registerLimitReached, detail: detail),
    UnauthenticatedFailure() => (title: l10n.loginFailedTitle, detail: detail),
    ValidationFailure() => (
      title: signingIn ? l10n.loginFailedTitle : l10n.registerFailedTitle,
      detail: detail,
    ),
    _ => authFailureText(l10n, failure),
  };
}
