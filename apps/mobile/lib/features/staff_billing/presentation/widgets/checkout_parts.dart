import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import 'billing_parts.dart';

/// Carries out a checkout the academy has opened (§11). What happens is decided by this build and by
/// the shape of the order, never by the app guessing at the payment:
///
/// - this build takes no payments (`BILLING_CHECKOUT_ENABLED` off, the default — C4), or it cannot
///   run this gateway: the invoice is ready and is paid from the web dashboard, said honestly;
/// - the academy gave a payment page: it opens outside the app, and the plan changes here only once
///   the academy confirms the payment;
/// - a gateway SDK this build carries: its result goes back to the academy, which is asked again
///   while the bank has not settled it, and its answer is what the screen shows.
Future<void> carryOutCheckout(
  BuildContext context,
  WidgetRef ref, {
  required CheckoutPlan plan,
  required CheckoutStart start,
}) async {
  final l10n = context.l10n;
  final runner = ref.read(nativeCheckoutRunnerProvider);
  final route = ref.read(checkoutEnabledProvider) ? plan.route : CheckoutRoute.unsupported;

  switch (route) {
    case CheckoutRoute.hostedPage:
      await ref.read(openExternalLinkProvider)(plan.hostedUrl!);
      if (!context.mounted) return;
      await _showMessageSheet(
        context,
        title: l10n.billingCheckoutHostedTitle,
        message: l10n.billingCheckoutHostedBody,
      );
      if (context.mounted) ref.invalidate(tenantBillingProvider);
    case CheckoutRoute.native when runner != null:
      final controller = ref.read(billingActionProvider.notifier);
      final result = await runner(plan.params);
      switch (result) {
        case GatewayCompleted(:final orderId, :final paymentId, :final signature):
          final outcome = await controller.confirm(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          );
          if (outcome != null && context.mounted) {
            showAppSnackbar(
              context,
              outcome.message.isNotEmpty ? outcome.message : l10n.billingCheckoutConfirmed,
              tone: outcome.settled ? SnackTone.success : SnackTone.info,
            );
          }
        case GatewayNotCompleted():
          controller.paymentNotCompleted();
          if (context.mounted) {
            showAppSnackbar(context, l10n.billingPaymentNotCompleted, tone: SnackTone.error);
          }
      }
    case CheckoutRoute.native || CheckoutRoute.unsupported:
      await _showMessageSheet(
        context,
        title: l10n.billingInvoiceReadyTitle,
        message: l10n.billingInvoiceReady(
          start.invoice.number,
          money(start.invoice.total, start.invoice.currency),
        ),
      );
      // The invoice now exists, so the billing page lists it.
      if (context.mounted) ref.invalidate(tenantBillingProvider);
  }
}

Future<void> _showMessageSheet(
  BuildContext context, {
  required String title,
  required String message,
}) => showAppBottomSheet<void>(
  context,
  builder: (sheet) => AppBottomSheet(
    title: title,
    footer: AppButton(label: sheet.l10n.actionDone, onPressed: () => Navigator.of(sheet).pop()),
    child: Semantics(liveRegion: true, child: Text(message, style: sheet.type.bodyM)),
  ),
);

/// Makes sure the academy has billing details before something that is charged — asking for them
/// when it has none. Answers whether they are in place.
Future<bool> ensureBillingDetails(BuildContext context, WidgetRef ref) async {
  final (:details, :failure) = await ref.read(billingActionProvider.notifier).readBillingDetails();
  if (failure != null) {
    if (context.mounted) {
      showAppSnackbar(
        context,
        failure.message ?? context.l10n.stateErrorBody,
        tone: SnackTone.error,
      );
    }
    return false;
  }
  if (details != null) return true;
  if (!context.mounted) return false;
  return showBillingDetailsSheet(context);
}

/// The academy's billing details form. Answers `true` once the academy has stored them.
Future<bool> showBillingDetailsSheet(BuildContext context, {BillingDetails? initial}) async {
  final saved = await showAppBottomSheet<bool>(
    context,
    builder: (_) => BillingDetailsSheet(initial: initial),
  );
  if (saved ?? false) {
    if (context.mounted) {
      showAppSnackbar(context, context.l10n.billingDetailsSaved, tone: SnackTone.success);
    }
    return true;
  }
  return false;
}

/// Where the academy's invoices are addressed (`PUT /tenant/billing-profile`). The form checks what
/// the academy will check, so it can say what is missing before sending; the academy's own refusal
/// is shown beside the field it names.
class BillingDetailsSheet extends ConsumerStatefulWidget {
  const BillingDetailsSheet({super.key, this.initial});

  final BillingDetails? initial;

  @override
  ConsumerState<BillingDetailsSheet> createState() => _BillingDetailsSheetState();
}

class _BillingDetailsSheetState extends ConsumerState<BillingDetailsSheet> {
  late final _fields = {
    for (final field in BillingDetailsField.values)
      field: TextEditingController(text: _initialOf(field)),
  };
  late final _addressLine2 = TextEditingController(text: widget.initial?.addressLine2 ?? '');
  Set<BillingDetailsField> _issues = const {};
  Map<String, String> _serverIssues = const {};
  String? _error;
  bool _busy = false;
  bool _tried = false;

  String _initialOf(BillingDetailsField field) {
    final d = widget.initial ?? const BillingDetails();
    return switch (field) {
      BillingDetailsField.legalName => d.legalName,
      BillingDetailsField.email => d.email,
      BillingDetailsField.addressLine1 => d.addressLine1,
      BillingDetailsField.city => d.city,
      BillingDetailsField.region => d.region ?? '',
      BillingDetailsField.postalCode => d.postalCode,
      BillingDetailsField.country => d.country,
      BillingDetailsField.taxRegistration => d.taxRegistration ?? '',
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _addressLine2.dispose();
    super.dispose();
  }

  BillingDetails get _draft => BillingDetails(
    legalName: _fields[BillingDetailsField.legalName]!.text,
    email: _fields[BillingDetailsField.email]!.text,
    addressLine1: _fields[BillingDetailsField.addressLine1]!.text,
    addressLine2: _addressLine2.text,
    city: _fields[BillingDetailsField.city]!.text,
    region: _fields[BillingDetailsField.region]!.text,
    postalCode: _fields[BillingDetailsField.postalCode]!.text,
    country: _fields[BillingDetailsField.country]!.text,
    taxRegistration: _fields[BillingDetailsField.taxRegistration]!.text,
  );

  Future<void> _save() async {
    final draft = _draft;
    final issues = billingDetailsIssues(draft);
    setState(() {
      _tried = true;
      _issues = issues;
      _serverIssues = const {};
      _error = null;
    });
    if (issues.isNotEmpty) return;

    setState(() => _busy = true);
    final failure = await ref.read(billingActionProvider.notifier).saveBillingDetails(draft);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final fieldIssues = switch (failure) {
      ValidationFailure(:final issues) || ConflictFailure(:final issues) => issues,
      _ => const <FieldIssue>[],
    };
    setState(() {
      _busy = false;
      _serverIssues = {for (final issue in fieldIssues) ?issue.key: issue.message};
      _error = _serverIssues.isEmpty ? failure.message ?? context.l10n.stateErrorBody : null;
    });
  }

  String? _errorFor(BillingDetailsField field) {
    final server = _serverIssues[field.name];
    if (server != null) return server;
    if (!_tried || !_issues.contains(field)) return null;
    final l10n = context.l10n;
    return switch (field) {
      BillingDetailsField.legalName => l10n.billingDetailsErrorLegalName,
      BillingDetailsField.email => l10n.billingDetailsErrorEmail,
      BillingDetailsField.addressLine1 => l10n.billingDetailsErrorAddress,
      BillingDetailsField.city => l10n.billingDetailsErrorCity,
      BillingDetailsField.region => l10n.billingDetailsErrorRegion,
      BillingDetailsField.postalCode => l10n.billingDetailsErrorPostalCode,
      BillingDetailsField.country => l10n.billingDetailsErrorCountry,
      BillingDetailsField.taxRegistration => l10n.billingDetailsErrorTax,
    };
  }

  Widget _field(
    BillingDetailsField field,
    String label, {
    bool required = true,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s3),
    child: AppTextField(
      label: label,
      controller: _fields[field],
      required: required,
      enabled: !_busy,
      errorText: _errorFor(field),
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLength: maxLength,
      textInputAction: TextInputAction.next,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppBottomSheet(
      title: l10n.billingDetailsTitle,
      footer: AppButton(label: l10n.billingDetailsSave, busy: _busy, onPressed: _save),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.billingDetailsBody, style: context.type.bodyS.copyWith(color: c.muted)),
          const SizedBox(height: Space.s4),
          _field(BillingDetailsField.legalName, l10n.billingDetailsLegalName, maxLength: 200),
          _field(
            BillingDetailsField.email,
            l10n.billingDetailsEmail,
            keyboardType: TextInputType.emailAddress,
            maxLength: 254,
          ),
          _field(BillingDetailsField.addressLine1, l10n.billingDetailsAddressLine1, maxLength: 200),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s3),
            child: AppTextField(
              label: l10n.billingDetailsAddressLine2,
              controller: _addressLine2,
              enabled: !_busy,
              maxLength: 200,
              errorText: _serverIssues['addressLine2'],
            ),
          ),
          _field(BillingDetailsField.city, l10n.billingDetailsCity, maxLength: 100),
          _field(
            BillingDetailsField.region,
            l10n.billingDetailsRegion,
            required: false,
            capitalization: TextCapitalization.characters,
            maxLength: 10,
          ),
          _field(BillingDetailsField.postalCode, l10n.billingDetailsPostalCode, maxLength: 20),
          _field(
            BillingDetailsField.country,
            l10n.billingDetailsCountry,
            capitalization: TextCapitalization.characters,
            maxLength: 2,
          ),
          _field(
            BillingDetailsField.taxRegistration,
            l10n.billingDetailsTaxRegistration,
            required: false,
            capitalization: TextCapitalization.characters,
            maxLength: 40,
          ),
          if (_error case final error?)
            Semantics(
              liveRegion: true,
              child: Text(error, style: context.type.bodyS.copyWith(color: c.dangerInk)),
            ),
        ],
      ),
    );
  }
}

/// Shows what moving to [plan] on [cycle] would do, as the academy previews it, before anything is
/// asked for. Answers the change once the academy has quoted it, or `null`.
Future<PlanChangeStart?> showPlanChangeSheet(
  BuildContext context, {
  required PlanView plan,
  required BillingCycle cycle,
  required TenantBilling billing,
}) => showAppBottomSheet<PlanChangeStart>(
  context,
  builder: (_) => PlanChangeSheet(plan: plan, cycle: cycle, billing: billing),
);

/// The preview of one plan change: the credit, the charge, the tax and the total for a change paid
/// now; the date and any limits already over for one that waits for the period to end. Every figure
/// is the academy's, and nothing is asked for until the admin confirms.
class PlanChangeSheet extends ConsumerWidget {
  const PlanChangeSheet({
    required this.plan,
    required this.cycle,
    required this.billing,
    super.key,
  });

  final PlanView plan;
  final BillingCycle cycle;
  final TenantBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = (planId: plan.id, cycle: cycle);
    final preview = ref.watch(planChangePreviewProvider(choice));
    final action = ref.watch(billingActionProvider);

    Future<void> confirm() async {
      final quote = await ref
          .read(billingActionProvider.notifier)
          .changePlan(planId: plan.id, cycle: cycle);
      if (quote != null && context.mounted) Navigator.of(context).pop(quote);
    }

    final ready = preview.value;
    // An upgrade paid here goes straight on to the gateway: the button says so, rather than "ask".
    final paysNow =
        ready != null &&
        ready.appliesOnPayment &&
        mayPayInApp(enabledInBuild: ref.watch(checkoutEnabledProvider), billing: billing);
    return AppBottomSheet(
      title: l10n.planChangeTitle(plan.name),
      footer: ready == null || ready.needsBillingAddress
          ? null
          : AppButton(
              label: paysNow ? l10n.planChangeContinueToPayment : l10n.planChangeConfirm,
              busy: action.busy,
              onPressed: confirm,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cycle == BillingCycle.annual
                ? l10n.billingPlanCycleAnnual
                : l10n.billingPlanCycleMonthly,
            style: context.type.bodyS.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: Space.s3),
          switch (preview) {
            AsyncData(:final value) => _Preview(
              preview: value,
              billing: billing,
              onAddDetails: () async {
                if (await showBillingDetailsSheet(context)) {
                  ref.invalidate(planChangePreviewProvider(choice));
                }
              },
            ),
            AsyncError(:final error) => BillingNotice(
              tone: Tone.warn,
              message: failureOf(error)?.message ?? l10n.stateErrorBody,
            ),
            _ => const SkeletonCard(),
          },
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.preview, required this.billing, required this.onAddDetails});

  final PlanChangePreview preview;
  final TenantBilling billing;
  final VoidCallback onAddDetails;

  String _labelOf(String limit) =>
      billing.usage.where((line) => line.limit == limit).firstOrNull?.label ?? limit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = preview.currency;

    if (preview.needsBillingAddress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BillingNotice(tone: Tone.info, message: l10n.billingDetailsNeeded),
          const SizedBox(height: Space.s3),
          AppButton(label: l10n.billingDetailsAddAction, onPressed: onAddDetails),
        ],
      );
    }

    if (preview.appliesOnPayment) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyValueTable(
            rows: [
              if (preview.credit > 0) (l10n.planChangeCredit, money(preview.credit, currency)),
              if (preview.payable case final payable?) ...[
                (l10n.planChangeNet, money(payable.net, currency)),
                (l10n.planChangeTax, money(payable.tax, currency)),
                (l10n.planChangeTotal, money(payable.gross, currency)),
              ] else
                (l10n.planChangeTotal, money(preview.charge, currency)),
            ],
          ),
          const SizedBox(height: Space.s3),
          Text(l10n.planChangeAppliesOnPayment, style: context.type.bodyS),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.planChangeAppliesOn(DatesIst.date(preview.appliesAt)), style: context.type.bodyM),
        if (preview.conflicts.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          BillingNotice(
            tone: Tone.warn,
            title: l10n.planChangeConflictsTitle,
            message: [
              for (final conflict in preview.conflicts)
                l10n.planChangeConflict(
                  _labelOf(conflict.limit),
                  conflict.usage,
                  conflict.newLimit,
                ),
            ].join('\n'),
          ),
        ],
      ],
    );
  }
}
