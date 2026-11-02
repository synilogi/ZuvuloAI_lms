import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import 'auth_scaffold.dart';
import 'join_link_parts.dart';

/// The 6-digit code a learner or an instructor who registered themselves is emailed — the second
/// step of every self-registration form (Create account, an invitation, a course link, a request to
/// teach). Nothing that can sign in exists until the code is entered. The screen around it keeps the
/// details that were typed, so going back to them changes nothing ([onChangeDetails]), and its
/// controller does the calls: this only draws the step and counts down to the next code.
class EmailCodeStep extends StatefulWidget {
  const EmailCodeStep({
    required this.pending,
    required this.state,
    required this.onVerify,
    required this.onResend,
    required this.onChangeDetails,
    super.key,
  });

  /// The registration the server holds, and its timings.
  final VerificationPending pending;

  /// The form's controller state: busy, the last refusal, and its issues by field.
  final AuthFormState state;

  /// Sends the code, already checked to be six digits.
  final Future<void> Function(String code) onVerify;

  /// Asks for a new code; true when one was sent (the screen then passes the renewed [pending]).
  final Future<bool> Function() onResend;

  /// Back to the details, as they were typed — also where "Start again" goes once the server has
  /// closed the registration.
  final VoidCallback onChangeDetails;

  @override
  State<EmailCodeStep> createState() => _EmailCodeStepState();
}

class _EmailCodeStepState extends State<EmailCodeStep> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  Timer? _ticker;

  /// Which call the last refusal answered, so it gets the right title.
  bool _resending = false;

  static final _sixDigits = RegExp(r'^\d{6}$');

  @override
  void initState() {
    super.initState();
    _tick();
  }

  @override
  void didUpdateWidget(EmailCodeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pending != widget.pending) {
      // A new code: the old one stops working, and the countdowns start again.
      _code.clear();
      _tick();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Duration _until(DateTime at) => at.difference(DateTime.now().toUtc());

  /// Seconds until a new code may be asked for (0 when it may now).
  int get _resendWait {
    final seconds = (_until(widget.pending.resendAvailableAt).inMilliseconds / 1000).ceil();
    return seconds < 0 ? 0 : seconds;
  }

  /// Whole minutes the code still works for, rounded up (0 once it has expired).
  int get _minutesLeft {
    final seconds = _until(widget.pending.expiresAt).inSeconds;
    return seconds <= 0 ? 0 : (seconds / 60).ceil();
  }

  void _tick() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (_resendWait == 0 && _minutesLeft == 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (widget.state.busy || !(_formKey.currentState?.validate() ?? false)) return;
    _resending = false;
    await widget.onVerify(_code.text.trim());
  }

  Future<void> _resend() async {
    _resending = true;
    final sent = await widget.onResend();
    if (sent && mounted) showAppSnackbar(context, context.l10n.academyCodeResent);
  }

  /// The server closed the registration (404 `VERIFICATION_FAILED`: used, replaced or long expired):
  /// only starting again can help.
  bool get _closed => widget.state.failure is NotFoundFailure;

  Widget? _banner(AppLocalizations l10n) {
    final failure = widget.state.failure;
    if (failure == null) return null;
    if (_closed) {
      return AuthErrorBanner(
        title: l10n.accountVerifyClosedTitle,
        detail: failure.message ?? l10n.accountVerifyClosedBody,
      );
    }
    // A wrong or expired code is said on the field itself.
    if (widget.state.fieldErrors.containsKey('code')) return null;
    final text = joinFailureText(l10n, failure, notFoundTitle: l10n.accountVerifyClosedTitle);
    final fallback = _resending
        ? l10n.accountVerifyResendFailedTitle
        : l10n.academyVerifyFailedTitle;
    return AuthErrorBanner(
      title: text.title == l10n.stateErrorTitle ? fallback : text.title,
      detail: text.detail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = widget.pending;
    final state = widget.state;
    final instructor = pending.role == 'instructor';
    final lms = pending.lms.trim();
    final wait = _resendWait;
    final minutes = _minutesLeft;
    final closed = _closed;
    return PopScope(
      // Back from the code is back to the details, not off the screen with them.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onChangeDetails();
      },
      child: AuthScaffold(
        title: l10n.academyVerifyTitle,
        subtitle: lms.isEmpty
            ? l10n.accountVerifySubtitleGeneric(pending.email)
            : instructor
            ? l10n.accountVerifyInstructorSubtitle(pending.email, lms)
            : l10n.accountVerifySubtitle(pending.email, lms),
        banner: _banner(l10n),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.fieldVerificationCode,
                  controller: _code,
                  enabled: !closed,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  errorText: state.fieldErrors['code'],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _sixDigits.hasMatch((v ?? '').trim())
                      ? null
                      : l10n.validationVerificationCode,
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: Space.s2),
                Semantics(
                  liveRegion: minutes == 0,
                  child: Text(
                    minutes > 0 ? l10n.accountVerifyExpiresIn(minutes) : l10n.accountVerifyExpired,
                    style: context.type.bodyS.copyWith(color: context.colors.muted),
                  ),
                ),
                const SizedBox(height: Space.s4),
                if (closed)
                  AppButton(
                    label: l10n.accountVerifyStartAgain,
                    size: AppButtonSize.lg,
                    expand: true,
                    onPressed: widget.onChangeDetails,
                  )
                else ...[
                  AppButton(
                    label: instructor
                        ? l10n.accountVerifyInstructorAction
                        : l10n.accountVerifyAction,
                    size: AppButtonSize.lg,
                    expand: true,
                    busy: state.busy,
                    onPressed: _verify,
                  ),
                  const SizedBox(height: Space.s3),
                  AppButton(
                    label: wait > 0 ? l10n.academyResendIn(wait) : l10n.academyResendCode,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: wait > 0 || state.busy ? null : _resend,
                  ),
                  const SizedBox(height: Space.s2),
                  TextButton(
                    onPressed: widget.onChangeDetails,
                    child: Text(l10n.academyChangeDetails),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
