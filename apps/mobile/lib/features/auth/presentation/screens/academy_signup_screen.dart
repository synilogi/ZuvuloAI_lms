import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/redirect.dart';
import '../../../../app/routing/routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/auth_form.dart';
import '../../application/session_controller.dart';
import '../auth_messages.dart';
import '../widgets/auth_scaffold.dart';

/// Start your LMS — the website's Get started (`/signup`), in two steps: the academy and its admin,
/// then the 6-digit code emailed to them. The registrant is always the new academy's admin, and the
/// academy starts with no plan: once signed in, the admin lands on the plan page (free trial or a
/// plan), exactly as on the web.
class AcademySignupScreen extends ConsumerStatefulWidget {
  const AcademySignupScreen({super.key, this.next});

  /// Where to continue once signed in — validated, as on the sign-in screen.
  final String? next;

  /// An LMS address from an academy's name, as the server makes one: `Saraswati Coaching` → `saraswati-coaching`.
  static String addressFrom(String name) {
    var slug = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.length > 40) slug = slug.substring(0, 40).replaceAll(RegExp(r'-+$'), '');
    return slug;
  }

  @override
  ConsumerState<AcademySignupScreen> createState() => _AcademySignupScreenState();
}

class _AcademySignupScreenState extends ConsumerState<AcademySignupScreen> {
  final _detailsKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  final _academyName = TextEditingController();
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _code = TextEditingController();

  /// False until the person edits the address: until then it follows the academy's name.
  bool _addressEdited = false;
  bool _agreed = false;
  bool _showAgreeError = false;

  /// Set once the server is waiting for the code.
  SignupPending? _pending;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in [_academyName, _address, _name, _email, _password, _confirm, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onAcademyName(String value) {
    if (_addressEdited) return;
    setState(() => _address.text = AcademySignupScreen.addressFrom(value));
  }

  /// Seconds until a new code may be asked for (0 when it may now).
  int get _resendWait {
    final at = _pending?.resendAvailableAt;
    if (at == null) return 0;
    final seconds = (at.difference(DateTime.now().toUtc()).inMilliseconds / 1000).ceil();
    return seconds < 0 ? 0 : seconds;
  }

  void _await(SignupPending pending) {
    _ticker?.cancel();
    setState(() => _pending = pending);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (_resendWait == 0) timer.cancel();
    });
  }

  Future<void> _start() async {
    final valid = _detailsKey.currentState?.validate() ?? false;
    setState(() => _showAgreeError = !_agreed);
    if (!valid || !_agreed) return;
    final step = await ref
        .read(academySignupControllerProvider.notifier)
        .start(
          academyName: _academyName.text,
          slug: _address.text,
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    switch (step) {
      case SignupNeedsCode(:final pending):
        _await(pending);
      case SignupDone():
        _continue();
      case null:
        break;
    }
  }

  Future<void> _verify() async {
    final pending = _pending;
    if (pending == null || !(_codeKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(academySignupControllerProvider.notifier)
        .verify(signupId: pending.signupId, code: _code.text);
    if (ok && mounted) _continue();
  }

  Future<void> _resend() async {
    final pending = _pending;
    if (pending == null) return;
    final renewed = await ref
        .read(academySignupControllerProvider.notifier)
        .resend(pending.signupId);
    if (renewed == null || !mounted) return;
    _code.clear();
    _await(renewed);
    showAppSnackbar(context, context.l10n.academyCodeResent);
  }

  void _changeDetails() {
    _ticker?.cancel();
    _code.clear();
    ref.read(academySignupControllerProvider.notifier).clear();
    setState(() => _pending = null);
  }

  /// Signed in as the new academy's admin: the router takes them to their plan page.
  void _continue() {
    final router = GoRouter.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    continueAfterSignIn(
      router: router,
      profile: ref.read(sessionControllerProvider).user,
      next: widget.next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academySignupControllerProvider);
    final pending = _pending;
    return pending == null ? _details(context, state) : _verifyForm(context, state, pending);
  }

  Widget? _banner(BuildContext context, AuthFormState state, String fallbackTitle) {
    final failure = state.failure;
    if (failure == null) return null;
    final l10n = context.l10n;
    final text = authFailureText(l10n, failure);
    return AuthErrorBanner(
      title: text.title == l10n.stateErrorTitle ? fallbackTitle : text.title,
      detail: text.detail,
    );
  }

  Widget _details(BuildContext context, AuthFormState state) {
    final l10n = context.l10n;
    final web = ref.watch(appConfigProvider).webBaseUrl;
    final address = _address.text.trim();
    return AuthScaffold(
      brand: true,
      title: l10n.academySignupTitle,
      subtitle: l10n.academySignupSubtitle,
      banner: _banner(context, state, l10n.academySignupFailedTitle),
      children: [
        Form(
          key: _detailsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fieldAcademyName,
                controller: _academyName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.organizationName],
                errorText: state.fieldErrors['academyName'],
                onChanged: _onAcademyName,
                validator: (v) => (v ?? '').trim().length < 2 ? l10n.validationAcademyName : null,
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldAcademyAddress,
                controller: _address,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                helperText: address.isEmpty
                    ? null
                    : l10n.fieldAcademyAddressHelp('${web.host}/join/$address'),
                errorText: state.fieldErrors['slug'],
                onChanged: (_) => setState(() => _addressEdited = true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
                  LowerCaseFormatter(),
                ],
                validator: (v) => AuthValidators.workspace(l10n, v) == null
                    ? null
                    : l10n.validationAcademyAddress,
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldYourName,
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                errorText: state.fieldErrors['name'],
                validator: (v) => AuthValidators.name(l10n, v),
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: state.fieldErrors['email'],
                validator: (v) => AuthValidators.email(l10n, v),
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldPassword,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                helperText: l10n.validationPasswordMin,
                errorText: state.fieldErrors['password'],
                validator: (v) => AuthValidators.newPassword(l10n, v),
              ),
              const SizedBox(height: Space.s4),
              AppTextField(
                label: l10n.fieldConfirmPassword,
                controller: _confirm,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => AuthValidators.confirmPassword(l10n, v, _password.text),
              ),
              const SizedBox(height: Space.s3),
              AppCheckboxRow(
                title: l10n.academySignupAgree,
                subtitle: _showAgreeError && !_agreed
                    ? l10n.validationAgreeTerms
                    : state.fieldErrors['acceptTerms'],
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => GoRouter.of(context).push(AppRoutes.terms),
                    child: Text(l10n.legalTermsTitle),
                  ),
                  TextButton(
                    onPressed: () => GoRouter.of(context).push(AppRoutes.privacy),
                    child: Text(l10n.legalPrivacyTitle),
                  ),
                ],
              ),
              const SizedBox(height: Space.s3),
              AppButton(
                label: l10n.actionContinue,
                size: AppButtonSize.lg,
                expand: true,
                busy: state.busy,
                onPressed: _start,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verifyForm(BuildContext context, AuthFormState state, SignupPending pending) {
    final l10n = context.l10n;
    final wait = _resendWait;
    return AuthScaffold(
      title: l10n.academyVerifyTitle,
      subtitle: l10n.academyVerifySubtitle(pending.email),
      banner: _banner(context, state, l10n.academyVerifyFailedTitle),
      children: [
        Form(
          key: _codeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n.fieldVerificationCode,
                controller: _code,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                errorText: state.fieldErrors['code'],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                    ? null
                    : l10n.validationVerificationCode,
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: Space.s4),
              AppButton(
                label: l10n.academyVerifyAction,
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
              TextButton(onPressed: _changeDetails, child: Text(l10n.academyChangeDetails)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lower-cases what is typed, so an LMS address is always in the server's form.
class LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
