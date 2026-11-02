import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/notifications_controller.dart';

/// The academy's own name for a category.
String categoryLabel(AppLocalizations l10n, NotificationCategory category) => switch (category) {
  NotificationCategory.course => l10n.notificationCategoryCourse,
  NotificationCategory.assignment => l10n.notificationCategoryAssignment,
  NotificationCategory.quiz => l10n.notificationCategoryQuiz,
  NotificationCategory.live => l10n.notificationCategoryLive,
  NotificationCategory.certificate => l10n.notificationCategoryCertificate,
  NotificationCategory.enrollment => l10n.notificationCategoryEnrollment,
  NotificationCategory.system => l10n.notificationCategorySystem,
  NotificationCategory.unknown => l10n.notificationCategorySystem,
};

/// The icon a category carries, from the app's own set.
IconData categoryIcon(NotificationCategory category) => switch (category) {
  NotificationCategory.course => AppIcons.courses,
  NotificationCategory.assignment => AppIcons.assignment,
  NotificationCategory.quiz => AppIcons.quiz,
  NotificationCategory.live => AppIcons.live,
  NotificationCategory.certificate => AppIcons.certificate,
  NotificationCategory.enrollment => AppIcons.people,
  NotificationCategory.system => AppIcons.settings,
  NotificationCategory.unknown => AppIcons.notifications,
};

/// The hue a category is drawn in while unread — the kind of thing it is about, at a glance.
/// System notices carry no hue.
Hue? categoryHue(NotificationCategory category) => switch (category) {
  NotificationCategory.course => Hue.violet,
  NotificationCategory.assignment => Hue.orange,
  NotificationCategory.quiz => Hue.pink,
  NotificationCategory.live => Hue.blue,
  NotificationCategory.certificate => Hue.gold,
  NotificationCategory.enrollment => Hue.green,
  NotificationCategory.system || NotificationCategory.unknown => null,
};

/// One notification in the list: what it is about, when it arrived, and whether it has been read.
class NotificationRow extends StatelessWidget {
  const NotificationRow({
    required this.notification,
    required this.onOpen,
    super.key,
    this.now,
    this.onToggleRead,
    this.onRemove,
  });

  final AppNotification notification;
  final VoidCallback onOpen;

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;
  final VoidCallback? onToggleRead;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final at = now ?? DateTime.now();
    final hue = categoryHue(notification.category);
    final card = AppCard(
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unread reads through the category's coloured tile and the dot, not a tinted card; read,
          // the tile goes quiet.
          if (notification.unread && hue != null)
            HueTile(icon: categoryIcon(notification.category), hue: hue, size: AvatarSizes.md)
          else
            IconTile(
              icon: categoryIcon(notification.category),
              tone: notification.unread ? Tone.accent : Tone.neutral,
              size: AvatarSizes.md,
            ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryLabel(l10n, notification.category),
                        style: context.type.caption.copyWith(
                          color: notification.unread && hue != null ? c.hue(hue).ink : c.muted,
                          fontWeight: notification.unread ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                    if (notification.important) const StatusBadge(StatusKind.important),
                    if (notification.unread) ...[
                      const SizedBox(width: Space.s2),
                      Semantics(
                        label: l10n.notificationsTabUnread,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Space.s1),
                Text(
                  notification.title,
                  style: notification.unread
                      ? context.type.titleS.copyWith(fontWeight: FontWeight.w700)
                      : context.type.titleS,
                ),
                if (notification.summary.isNotEmpty) ...[
                  const SizedBox(height: Space.s1),
                  Text(
                    notification.summary,
                    style: context.type.bodyS.copyWith(color: c.muted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: Space.s2),
                Text(
                  DatesIst.relative(l10n, notification.createdAt, at),
                  style: context.type.caption.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          if (onToggleRead != null || onRemove != null)
            PopupMenuButton<String>(
              icon: AppIcon(AppIcons.more, color: c.muted),
              tooltip: l10n.actionMore,
              onSelected: (value) {
                if (value == 'read') onToggleRead?.call();
                if (value == 'remove') onRemove?.call();
              },
              itemBuilder: (context) => [
                if (onToggleRead != null)
                  PopupMenuItem(
                    value: 'read',
                    child: Text(
                      notification.unread
                          ? l10n.notificationsMarkRead
                          : l10n.notificationsMarkUnread,
                    ),
                  ),
                if (onRemove != null)
                  PopupMenuItem(value: 'remove', child: Text(l10n.notificationsRemove)),
              ],
            ),
        ],
      ),
    );
    if (onRemove == null) return card;
    return Dismissible(
      key: ValueKey('dismiss-${notification.id}'),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: c.dangerSoft,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: Space.s4),
            child: Text(
              l10n.notificationsRemove,
              style: context.type.label.copyWith(color: c.dangerInk),
            ),
          ),
        ),
      ),
      onDismissed: (_) => onRemove!(),
      child: card,
    );
  }
}

/// The category filter, carrying the academy's own unread counts.
class NotificationCategoryBar extends StatelessWidget {
  const NotificationCategoryBar({
    required this.page,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final NotificationPage page;
  final NotificationCategory? selected;
  final void Function(NotificationCategory? category) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FilterChipBar<NotificationCategory?>(
      options: [
        FilterOption(null, l10n.notificationsTabAll),
        for (final category in notificationCategories)
          FilterOption(category, categoryLabel(l10n, category), count: page.unreadIn(category)),
      ],
      selected: selected,
      onSelected: onSelect,
    );
  }
}
