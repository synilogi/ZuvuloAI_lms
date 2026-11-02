import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/web_path_mapper.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../application/notifications_controller.dart';
import '../widgets/notification_parts.dart';

/// `/notifications/:notificationId` — one notice in full. Opening it marks it read, which is the
/// route's own doing (§12).
class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({required this.notificationId, super.key});

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider)?.role ?? UserRole.unknown;
    final staff = role == UserRole.instructor || role == UserRole.admin;
    return AsyncView<NotificationDetail>(
      value: ref.watch(notificationDetailProvider(notificationId)),
      onRetry: () => ref.invalidate(notificationDetailProvider(notificationId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(
        onBack: () =>
            GoRouter.of(context).go(staff ? AppRoutes.staffNotifications : AppRoutes.notifications),
      ),
      data: (detail) => _Notification(detail: detail, role: role),
    );
  }
}

class _Notification extends ConsumerWidget {
  const _Notification({required this.detail, required this.role});

  final NotificationDetail detail;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final n = detail.notification;
    final staff = role == UserRole.instructor || role == UserRole.admin;
    final channels = [
      if (detail.sendsOn(NotificationChannel.app)) l10n.notificationChannelApp,
      if (detail.sendsOn(NotificationChannel.email)) l10n.notificationChannelEmail,
      if (detail.sendsOn(NotificationChannel.sms)) l10n.notificationChannelSms,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
      children: [
        DetailHeader(
          icon: categoryIcon(n.category),
          tone: n.important ? Tone.danger : Tone.accent,
          eyebrow: categoryLabel(l10n, n.category),
          badge: n.important ? const StatusBadge(StatusKind.late) : null,
          title: n.title,
          facts: [
            MetaItem(icon: AppIcons.time, label: DatesIst.dateTime(l10n, n.createdAt)),
            if (n.actor case final actor?) MetaItem(icon: AppIcons.profile, label: actor),
          ],
          footer: [
            if (n.summary.isNotEmpty) ...[
              const SizedBox(height: Space.s1),
              Text(n.summary, style: context.type.bodyM),
            ],
          ],
        ),
        for (final paragraph in n.body) ...[
          const SizedBox(height: Space.s3),
          Text(paragraph, style: context.type.bodyM),
        ],
        if (n.facts.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          AppCard(
            child: KeyValueTable(rows: [for (final fact in n.facts) (fact.label, fact.value)]),
          ),
        ],
        if (channels.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          Text(
            l10n.notificationSentOn(channels.join(', ')),
            style: context.type.caption.copyWith(color: c.muted),
          ),
        ],
        for (final action in [n.action, n.secondaryAction].nonNulls) ...[
          const SizedBox(height: Space.s3),
          _ActionButton(action: action, role: role, primary: action == n.action),
        ],
        if (detail.related.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(title: l10n.notificationRelatedTitle),
          for (final related in detail.related) ...[
            NotificationRow(
              notification: related,
              onOpen: () => GoRouter.of(context).go(
                staff
                    ? AppRoutes.staffNotification(related.id)
                    : AppRoutes.notification(related.id),
              ),
            ),
            const SizedBox(height: Space.s3),
          ],
        ],
      ],
    );
  }
}

/// A notification's action. The server sends a **web** path, which is mapped to one of the app's
/// own routes; anything the app does not recognise is shown without a way to follow it, and never
/// opened as a URL (§5.4, §18).
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.role, required this.primary});

  final NotificationAction action;
  final UserRole role;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final target = WebPathMapper.map(action.to, role);
    if (target == null) {
      return Text(action.label, style: context.type.bodyS.copyWith(color: context.colors.muted));
    }
    return AppButton(
      label: action.label,
      variant: primary ? AppButtonVariant.primary : AppButtonVariant.secondary,
      onPressed: () => GoRouter.of(context).go(target),
    );
  }
}
