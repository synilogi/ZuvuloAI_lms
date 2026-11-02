import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/course_purchase_controller.dart';

/// `/profile/purchases` — the courses this learner has bought or tried to: the course, what was
/// charged, where it stands and when. Every figure is the server's. A shell body.
class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(coursePurchasesProvider.future),
      child: AsyncView<List<CoursePurchase>>(
        value: ref.watch(coursePurchasesProvider),
        onRetry: () => ref.invalidate(coursePurchasesProvider),
        data: (rows) => rows.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 360,
                    child: EmptyState(
                      title: l10n.purchasesEmptyTitle,
                      message: l10n.purchasesEmptyBody,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s6),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.s3),
                itemBuilder: (context, i) => PurchaseCard(
                  purchase: rows[i],
                  onOpen: rows[i].courseId.isEmpty
                      ? null
                      : () => GoRouter.of(context).go(AppRoutes.learnCourse(rows[i].courseId)),
                ),
              ),
      ),
    );
  }
}

/// How a purchase's status reads, as the shared status badge draws it.
StatusKind purchaseStatusKind(CoursePurchase purchase) => switch (purchase.status) {
  CoursePurchaseStatus.paid => StatusKind.paid,
  CoursePurchaseStatus.failed => StatusKind.failed,
  CoursePurchaseStatus.expired => StatusKind.expired,
  CoursePurchaseStatus.created || CoursePurchaseStatus.unknown => StatusKind.pending,
};

/// One purchase: the course, the amount charged (paise, as the server sent it), the status, and the
/// day it was paid — or made, while it is not.
class PurchaseCard extends StatelessWidget {
  const PurchaseCard({required this.purchase, super.key, this.onOpen});

  final CoursePurchase purchase;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final c = context.colors;
    final day = purchase.paidAt ?? purchase.createdAt;
    final amount = Money.format(purchase.amount, purchase.currency, dropZeroFraction: true);
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  purchase.courseTitle,
                  style: type.titleS,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Space.s2),
              StatusBadge(purchaseStatusKind(purchase)),
            ],
          ),
          const SizedBox(height: Space.s2),
          Row(
            children: [
              Text(amount, style: type.titleM.copyWith(color: c.accentInk)),
              const Spacer(),
              if (day != null) Text(DatesIst.date(day), style: type.bodyS.copyWith(color: c.muted)),
            ],
          ),
          if (purchase.needsReview) ...[
            const SizedBox(height: Space.s2),
            Text(l10n.purchaseNeedsReview, style: type.bodyS.copyWith(color: c.warnInk)),
          ] else if (purchase.failureMessage case final message?
              when purchase.status != CoursePurchaseStatus.paid) ...[
            const SizedBox(height: Space.s2),
            Text(message, style: type.bodyS.copyWith(color: c.muted)),
          ],
        ],
      ),
    );
  }
}
