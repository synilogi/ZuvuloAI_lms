import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import '../widgets/billing_parts.dart';
import '../widgets/checkout_parts.dart';

/// `/staff/billing/invoices/:invoiceId` — one invoice, exactly as the academy issued it. The
/// subtotal, the tax and the total are the figures it fixed at the time: tax may be inclusive and
/// several components each round, so nothing here is added up again (§18). A shell body.
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(tenantInvoiceProvider(invoiceId).future),
      child: AsyncView<InvoiceView>(
        value: ref.watch(tenantInvoiceProvider(invoiceId)),
        onRetry: () => ref.invalidate(tenantInvoiceProvider(invoiceId)),
        data: (invoice) => _Invoice(invoice: invoice),
      ),
    );
  }
}

class _Invoice extends ConsumerWidget {
  const _Invoice({required this.invoice});

  final InvoiceView invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final amounts = invoice.amounts;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        DetailHeader(
          icon: AppIcons.subscription,
          tone: Tone.info,
          eyebrow: invoice.planName.isEmpty ? null : invoice.planName,
          badge: StatusBadge(
            invoiceStatusKind(invoice.status),
            labelOverride: invoiceStatusLabel(l10n, invoice.status),
          ),
          title: l10n.invoiceTitle(invoice.number),
          facts: [
            MetaItem(
              icon: AppIcons.date,
              label: l10n.invoicePeriod(
                DatesIst.date(invoice.periodStart),
                DatesIst.date(invoice.periodEnd),
              ),
            ),
            MetaItem(
              icon: AppIcons.time,
              label: l10n.invoiceIssued(DatesIst.date(invoice.issuedAt)),
            ),
            if (invoice.paidAt case final paidAt?)
              MetaItem(icon: AppIcons.success, label: l10n.invoicePaidOn(DatesIst.date(paidAt))),
          ],
          footer: [
            if (invoice.note case final note? when note.isNotEmpty)
              Text(note, style: context.type.bodyS.copyWith(color: c.muted)),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.invoiceLinesTitle,
          icon: AppIcons.list,
          iconColor: c.hue(Hue.violet).solid,
        ),
        GroupedList(
          children: [
            for (final line in invoice.lines)
              AppListTile(
                title: line.description,
                subtitle: line.quantity > 1 ? l10n.invoiceLineQuantity(line.quantity) : null,
                trailing: Text(money(line.unitAmount, invoice.currency), style: context.type.label),
              ),
          ],
        ),
        const SizedBox(height: Space.s3),
        if (amounts == null)
          Text(l10n.invoiceAmountsMissing, style: context.type.bodyS.copyWith(color: c.muted))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.cardPadding, vertical: Space.s1),
            child: KeyValueTable(
              rows: [
                (l10n.invoiceSubtotal, money(amounts.subtotal, invoice.currency)),
                (
                  invoice.taxPercent > 0
                      ? l10n.invoiceTaxPercent('${invoice.taxPercent}')
                      : l10n.invoiceTax,
                  money(amounts.tax, invoice.currency),
                ),
                (l10n.invoiceTotal, money(amounts.total, invoice.currency)),
              ],
            ),
          ),
        if (invoice.isPayable) ...[const SizedBox(height: Space.s3), _PayInvoice(invoice: invoice)],
        if (invoice.method.brand.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          Text(
            '${l10n.billingPaymentMethod}: ${invoice.method.label}',
            style: context.type.caption.copyWith(color: c.muted),
          ),
        ],
        if (invoice.billingAddress.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.billingBilledTo,
            icon: AppIcons.profile,
            iconColor: c.hue(Hue.green).solid,
          ),
          AppCard(
            child: Text(
              [invoice.customerName, ...invoice.billingAddress].join('\n'),
              style: context.type.bodyS,
            ),
          ),
        ],
      ],
    );
  }
}

/// How an open invoice is paid. A payment control exists only where this build takes payments
/// **and** the academy has a gateway connected; where only the academy does, the invoice is paid from
/// the web dashboard, and where neither does, nothing is offered here at all.
class _PayInvoice extends ConsumerWidget {
  const _PayInvoice({required this.invoice});

  final InvoiceView invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(checkoutEnabledProvider);
    // `/tenant/billing` is read only when this build could take the payment at all.
    final billing = enabled ? ref.watch(tenantBillingProvider).value : null;
    final mayChange = watchCan(ref, Capability.changeBilling);
    final action = ref.watch(billingActionProvider);

    if (billing != null && mayPayInApp(enabledInBuild: enabled, billing: billing) && mayChange) {
      Future<void> pay() async {
        final controller = ref.read(billingActionProvider.notifier);
        final checkout = await controller.startInvoicePayment(invoice.id);
        final start = ref.read(billingActionProvider).start;
        if (checkout == null || start == null || !context.mounted) return;
        await carryOutCheckout(context, ref, plan: checkout, start: start);
        if (context.mounted) ref.invalidate(tenantInvoiceProvider(invoice.id));
      }

      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: AppButton(label: l10n.billingPayInvoiceAction, busy: action.busy, onPressed: pay),
      );
    }
    return Text(
      l10n.billingPaymentNotOffered,
      style: context.type.caption.copyWith(color: context.colors.muted),
    );
  }
}
