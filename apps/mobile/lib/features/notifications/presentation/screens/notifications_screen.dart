import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../application/notifications_controller.dart';
import '../widgets/notification_parts.dart';

/// `/notifications` and `/staff/notifications` — the same centre for every role: all or unread,
/// filtered by the academy's own categories, with the counts it counted (§12). A shell body.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(notificationsProvider.future),
      child: AsyncView<NotificationPage>(
        value: ref.watch(notificationsProvider),
        onRetry: () => ref.invalidate(notificationsProvider),
        data: (page) => _Centre(page: page),
      ),
    );
  }
}

class _Centre extends ConsumerWidget {
  const _Centre({required this.page});

  final NotificationPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(notificationFilterProvider);
    final controller = ref.read(notificationFilterProvider.notifier);
    final actions = ref.read(notificationActionProvider.notifier);
    final action = ref.watch(notificationActionProvider);
    final busy = action.busy;
    // A notification the academy has already removed is not shown again while the list is read.
    final rows = [
      for (final row in page.rows)
        if (!action.removedIds.contains(row.id)) row,
    ];
    final offline = ref.watch(isOnlineProvider).value == false;
    final role = ref.watch(currentUserProvider)?.role;
    final staff = role == UserRole.instructor || role == UserRole.admin;

    ref.listen(notificationActionProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
      ref.read(notificationActionProvider.notifier).clearFailure();
    });

    void open(String id) => GoRouter.of(
      context,
    ).go(staff ? AppRoutes.staffNotification(id) : AppRoutes.notification(id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, 0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(l10n.notificationsTabAll)),
                    ButtonSegment(value: true, label: Text(l10n.notificationsTabUnread)),
                  ],
                  selected: {filter.unreadOnly},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      values.first ? controller.showUnreadOnly() : controller.showAll(),
                ),
              ),
              PopupMenuButton<String>(
                icon: AppIcon(AppIcons.more, color: context.colors.muted),
                tooltip: l10n.actionMore,
                enabled: !busy && !offline,
                onSelected: (value) async {
                  if (value == 'read-all') {
                    final changed = await actions.readAll(category: filter.category);
                    if (changed != null && context.mounted) {
                      showAppSnackbar(context, l10n.notificationsMarkedRead(changed));
                    }
                  }
                  if (value == 'clear' && context.mounted) await _clear(context, ref);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'read-all', child: Text(l10n.notificationsMarkAllRead)),
                  PopupMenuItem(value: 'clear', child: Text(l10n.notificationsClear)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s2),
        NotificationCategoryBar(
          page: page,
          selected: filter.category,
          onSelect: controller.inCategory,
        ),
        const SizedBox(height: Space.s3),
        Expanded(
          child: rows.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 320,
                      child: filter.unreadOnly || filter.category != null
                          ? EmptyState(
                              title: l10n.notificationsFilterEmpty,
                              actionLabel: l10n.actionClearFilters,
                              onAction: () {
                                controller
                                  ..showAll()
                                  ..inCategory(null);
                              },
                            )
                          : EmptyState(
                              title: l10n.notificationsEmptyTitle,
                              message: l10n.notificationsEmptyBody,
                            ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
                  itemCount: rows.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: Space.s3),
                  itemBuilder: (context, i) {
                    if (i == rows.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: Space.s2),
                        child: AppButton(
                          label: l10n.notificationsShowMore,
                          variant: AppButtonVariant.tertiary,
                          onPressed: controller.showMore,
                        ),
                      );
                    }
                    final row = rows[i];
                    return NotificationRow(
                      notification: row,
                      onOpen: () => open(row.id),
                      onToggleRead: offline
                          ? null
                          : () => actions.setRead([row.id], read: row.unread),
                      onRemove: offline ? null : () => _remove(context, ref, row),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, AppNotification notification) async {
    final l10n = context.l10n;
    final actions = ref.read(notificationActionProvider.notifier);
    final removed = await actions.remove(notification);
    if (!removed || !context.mounted) return;
    showAppSnackbar(
      context,
      l10n.notificationsRemoved,
      onUndo: () async {
        final restored = await actions.undo();
        if (restored && context.mounted) showAppSnackbar(context, l10n.notificationsRestored);
      },
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final filter = ref.read(notificationFilterProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: l10n.notificationsClearConfirmTitle,
        message: l10n.notificationsClearConfirmBody(page.total),
        confirmLabel: l10n.notificationsClear,
        destructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cleared = await ref
        .read(notificationActionProvider.notifier)
        .clear(category: filter.category, unreadOnly: filter.unreadOnly);
    if (cleared != null && context.mounted) {
      showAppSnackbar(context, l10n.notificationsCleared(cleared));
    }
  }
}
