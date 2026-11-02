import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../public_catalog/public_catalog.dart' show PriceTag;
import '../../application/course_purchase_controller.dart';

/// The bottom of a paid course the learner does not hold. In a build that sells courses in the app:
/// "Buy course · ₹X", an order summary, the gateway, and the server's word on the payment. In one
/// that does not (every production build — store billing rules), the price and one neutral line,
/// with no way to buy and no word about buying anywhere else.
class CoursePurchaseBar extends ConsumerStatefulWidget {
  const CoursePurchaseBar({required this.course, required this.price, super.key});

  final Course course;

  /// The course's price as the server sent it — whole rupees, all-inclusive. Shown, never charged:
  /// the order the server opens carries its own amount.
  final Price price;

  @override
  ConsumerState<CoursePurchaseBar> createState() => _CoursePurchaseBarState();
}

class _CoursePurchaseBarState extends ConsumerState<CoursePurchaseBar> {
  String get _courseId => widget.course.id;

  @override
  void initState() {
    super.initState();
    // A purchase left open on this device for this course (the app was closed mid-payment) is
    // asked about first: the course may already be paid for.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(courseCheckoutEnabledProvider)) return;
      ref.read(coursePurchaseProvider(_courseId).notifier).resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priceLabel = Money.formatMajor(widget.price.amount, widget.price.currency);
    if (!ref.watch(courseCheckoutEnabledProvider)) {
      return StickyActionBar(
        leading: PriceTag(course: widget.course),
        primary: Text(
          l10n.courseNotSoldInApp,
          style: context.type.bodyS.copyWith(color: context.colors.muted),
        ),
      );
    }

    final state = ref.watch(coursePurchaseProvider(_courseId));
    final controller = ref.read(coursePurchaseProvider(_courseId).notifier);
    final offline = ref.watch(isOnlineProvider).value == false;
    ref.listen(coursePurchaseProvider(_courseId), (previous, next) {
      if (next.stage == PurchaseStage.paid && previous?.stage != PurchaseStage.paid) {
        showAppSnackbar(context, l10n.purchasePaid, tone: SnackTone.success);
      }
    });

    final retry = switch (state.stage) {
      PurchaseStage.failed || PurchaseStage.cancelled || PurchaseStage.refused => true,
      _ => false,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (purchaseStatusText(l10n, state) case final status?)
          PurchaseStatusPanel(
            text: status,
            tone: purchaseStatusTone(state.stage),
            onCheckAgain: state.canCheckAgain && !offline ? controller.checkAgain : null,
          ),
        StickyActionBar(
          primary: AppButton(
            label: retry ? l10n.actionRetry : l10n.actionBuyCourse(priceLabel),
            size: AppButtonSize.lg,
            busy: state.busy,
            onPressed: offline || state.busy || state.stage == PurchaseStage.paid
                ? null
                : () => _buy(context, priceLabel),
          ),
        ),
      ],
    );
  }

  Future<void> _buy(BuildContext context, String priceLabel) async {
    final go = await showOrderSummary(context, title: widget.course.title, priceLabel: priceLabel);
    if (!go || !mounted) return;
    await ref.read(coursePurchaseProvider(_courseId).notifier).buy();
  }
}

/// The order before paying: the course, the final amount, and that it is all-inclusive. Answers
/// whether the learner chose to pay.
Future<bool> showOrderSummary(
  BuildContext context, {
  required String title,
  required String priceLabel,
}) async {
  final go = await showAppBottomSheet<bool>(
    context,
    builder: (sheet) {
      final l10n = sheet.l10n;
      final type = sheet.type;
      final c = sheet.colors;
      Widget row(String label, String value, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: type.bodyM.copyWith(color: c.muted)),
            ),
            const SizedBox(width: Space.s4),
            Flexible(
              flex: 2,
              child: Text(value, style: style ?? type.bodyM, textAlign: TextAlign.end),
            ),
          ],
        ),
      );
      return AppBottomSheet(
        title: l10n.purchaseSummaryTitle,
        footer: AppButton(
          label: l10n.actionPayAmount(priceLabel),
          size: AppButtonSize.lg,
          expand: true,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(l10n.purchaseSummaryCourse, title),
            const Divider(),
            row(
              l10n.purchaseSummaryTotal,
              priceLabel,
              style: type.titleM.copyWith(color: c.accentInk),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(l10n.purchaseSummaryAllInclusive, style: type.caption),
            ),
            const SizedBox(height: Space.s3),
            Text(l10n.purchaseSummaryNote, style: type.bodyS.copyWith(color: c.muted)),
          ],
        ),
      );
    },
  );
  return go ?? false;
}

/// What the learner reads about the purchase in flight, or null when there is nothing to say. The
/// app's own sentence comes first; the server's is used where it said something more specific.
String? purchaseStatusText(AppLocalizations l10n, CoursePurchaseState state) {
  return switch (state.stage) {
    PurchaseStage.idle => null,
    PurchaseStage.starting => l10n.purchaseStarting,
    PurchaseStage.atGateway => l10n.purchaseAtGateway,
    PurchaseStage.confirming => l10n.purchaseConfirming,
    PurchaseStage.waiting => l10n.purchaseWaiting,
    PurchaseStage.stillWaiting => l10n.purchaseStillWaiting,
    PurchaseStage.awayAtPage => l10n.purchaseAwayAtPage,
    PurchaseStage.paid => l10n.purchasePaid,
    PurchaseStage.failed => state.message ?? l10n.purchaseFailed,
    PurchaseStage.cancelled => l10n.purchaseCancelled,
    PurchaseStage.offline => l10n.purchaseOffline,
    PurchaseStage.unsupported => l10n.purchaseUnsupported,
    PurchaseStage.refused => switch (state.failure) {
      CourseSaleFailure(problem: CourseSaleProblem.paymentsNotSetUp) => l10n.purchaseNotSetUp,
      CourseSaleFailure(problem: CourseSaleProblem.notForSale) => l10n.purchaseNotForSale,
      CourseSaleFailure(problem: CourseSaleProblem.alreadyEnrolled) => l10n.purchaseAlreadyEnrolled,
      final failure? when failure.message != null => failure.message,
      _ => l10n.purchaseRefused,
    },
  };
}

Tone purchaseStatusTone(PurchaseStage stage) => switch (stage) {
  PurchaseStage.paid => Tone.accent,
  PurchaseStage.failed || PurchaseStage.refused || PurchaseStage.unsupported => Tone.danger,
  PurchaseStage.cancelled || PurchaseStage.offline || PurchaseStage.stillWaiting => Tone.warn,
  _ => Tone.info,
};

/// One line about the purchase above the bar, with "Check again" where the server may have news.
class PurchaseStatusPanel extends StatelessWidget {
  const PurchaseStatusPanel({required this.text, required this.tone, super.key, this.onCheckAgain});

  final String text;
  final Tone tone;
  final VoidCallback? onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (soft, ink) = switch (tone) {
      Tone.danger => (c.dangerSoft, c.dangerInk),
      Tone.warn => (c.warnSoft, c.warnInk),
      Tone.accent => (c.accentSoft, c.accentInk),
      Tone.info || Tone.neutral => (c.infoSoft, c.infoInk),
    };
    return ColoredBox(
      color: soft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(text, style: context.type.bodyS.copyWith(color: ink)),
              ),
            ),
            if (onCheckAgain != null) ...[
              const SizedBox(width: Space.s2),
              AppButton(
                label: context.l10n.actionCheckAgain,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: onCheckAgain,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whether [failure] is the server saying a paid course has to be bought (`COURSE_PURCHASE_REQUIRED`).
bool isPurchaseRequired(AppFailure? failure) =>
    failure is CourseSaleFailure && failure.problem == CourseSaleProblem.purchaseRequired;
