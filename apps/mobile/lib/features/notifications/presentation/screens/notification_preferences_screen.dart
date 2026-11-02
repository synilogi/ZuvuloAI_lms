import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/notifications_controller.dart';
import '../widgets/notification_parts.dart';

/// `…/notifications/preferences` — what the academy may send, how, and when it keeps quiet. The
/// shape is the server's own; the app only edits it (§12).
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<NotificationSettings>(
      value: ref.watch(notificationSettingsProvider),
      onRetry: () => ref.invalidate(notificationSettingsProvider),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      data: (_) => const _Preferences(),
    );
  }
}

class _Preferences extends ConsumerWidget {
  const _Preferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final draft = ref.watch(notificationSettingsDraftProvider);
    final controller = ref.read(notificationSettingsDraftProvider.notifier);
    final settings = draft.current;
    final offline = ref.watch(isOnlineProvider).value == false;

    ref.listen(notificationSettingsDraftProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
      ref.read(notificationSettingsDraftProvider.notifier).clearFailure();
    });

    if (settings == null) return const DelayedLoading(skeleton: SkeletonCard());
    final quietIssue = draft.issues
        .where((issue) => issue.field == 'quietHours')
        .firstOrNull
        ?.message;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
            children: [
              if (draft.issues.isNotEmpty) ...[
                FormErrorSummary(
                  issues: [for (final issue in draft.issues) FormIssue(message: issue.message)],
                ),
                const SizedBox(height: Space.s4),
              ],
              SectionHeader(title: l10n.notificationPrefsCategoriesTitle),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Space.s2),
                child: Column(
                  children: [
                    for (final category in notificationCategories)
                      _CategoryRow(
                        preference: settings.forCategory(category),
                        enabled: !offline && !draft.saving,
                        onChanged: (preference) =>
                            controller.edit(settings.withCategory(preference)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s2),
              Text(
                l10n.notificationPrefsLocked,
                style: context.type.caption.copyWith(color: c.muted),
              ),
              const SizedBox(height: Space.s2),
              Text(
                l10n.notificationPrefsSmsUnavailable,
                style: context.type.caption.copyWith(color: c.muted),
              ),
              const SizedBox(height: Space.sectionGap),
              SectionHeader(title: l10n.notificationPrefsDigestTitle),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: Space.s2),
                child: AppRadioGroup<EmailDigest>(
                  label: l10n.notificationPrefsDigestTitle,
                  value: settings.emailDigest,
                  options: [
                    for (final digest in const [
                      EmailDigest.instant,
                      EmailDigest.daily,
                      EmailDigest.weekly,
                      EmailDigest.off,
                    ])
                      RadioOption(digest, digestLabel(l10n, digest)),
                  ],
                  onChanged: offline || draft.saving
                      ? null
                      : (value) => controller.edit(settings.copyWith(emailDigest: value)),
                ),
              ),
              const SizedBox(height: Space.sectionGap),
              SectionHeader(title: l10n.notificationPrefsQuietTitle),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSwitchRow(
                      title: l10n.notificationPrefsQuietTitle,
                      subtitle: l10n.notificationPrefsQuietEnabled,
                      value: settings.quietHours.enabled,
                      onChanged: offline || draft.saving
                          ? null
                          : (on) => controller.edit(
                              settings.copyWith(
                                quietHours: settings.quietHours.copyWith(enabled: on),
                              ),
                            ),
                    ),
                    if (settings.quietHours.enabled) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _TimeField(
                              label: l10n.notificationPrefsQuietFrom,
                              value: settings.quietHours.from,
                              enabled: !offline && !draft.saving,
                              onChanged: (value) => controller.edit(
                                settings.copyWith(
                                  quietHours: settings.quietHours.copyWith(from: value),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Space.s3),
                          Expanded(
                            child: _TimeField(
                              label: l10n.notificationPrefsQuietTo,
                              value: settings.quietHours.to,
                              enabled: !offline && !draft.saving,
                              onChanged: (value) => controller.edit(
                                settings.copyWith(
                                  quietHours: settings.quietHours.copyWith(to: value),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.s2),
                      Text(
                        quietIssue ?? l10n.notificationPrefsQuietNote,
                        style: context.type.caption.copyWith(
                          color: quietIssue == null ? c.muted : c.dangerInk,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.sectionGap),
              SectionHeader(title: l10n.notificationPrefsPauseTitle),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (settings.pausedUntil case final until?) ...[
                      Text(
                        l10n.notificationPrefsPausedUntil(DatesIst.dateTime(l10n, until)),
                        style: context.type.bodyM,
                      ),
                      const SizedBox(height: Space.s3),
                      AppButton(
                        label: l10n.notificationPrefsResumeAction,
                        variant: AppButtonVariant.secondary,
                        onPressed: offline || draft.saving
                            ? null
                            : () => controller.edit(settings.copyWith(pausedUntil: null)),
                      ),
                    ] else
                      AppButton(
                        label: l10n.notificationPrefsPauseAction,
                        variant: AppButtonVariant.secondary,
                        onPressed: offline || draft.saving
                            ? null
                            : () => _pause(context, ref, settings),
                      ),
                    const SizedBox(height: Space.s2),
                    Text(
                      l10n.notificationPrefsPauseNote,
                      style: context.type.caption.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        StickyActionBar(
          primary: AppButton(
            label: l10n.actionSave,
            size: AppButtonSize.lg,
            busy: draft.saving,
            onPressed: offline || draft.saving || !draft.dirty
                ? null
                : () async {
                    final saved = await controller.save();
                    if (saved && context.mounted) {
                      showAppSnackbar(context, l10n.notificationPrefsSaved);
                    }
                  },
          ),
        ),
      ],
    );
  }

  /// Pausing takes a date and time in the future; the academy keeps sending important notices.
  Future<void> _pause(BuildContext context, WidgetRef ref, NotificationSettings settings) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !context.mounted) return;
    final until = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref
        .read(notificationSettingsDraftProvider.notifier)
        .edit(settings.copyWith(pausedUntil: until.toUtc()));
  }
}

/// The digest wording.
String digestLabel(AppLocalizations l10n, EmailDigest digest) => switch (digest) {
  EmailDigest.instant => l10n.notificationPrefsDigestInstant,
  EmailDigest.daily => l10n.notificationPrefsDigestDaily,
  EmailDigest.weekly => l10n.notificationPrefsDigestWeekly,
  EmailDigest.off || EmailDigest.unknown => l10n.notificationPrefsDigestOff,
};

/// One category's channels. A locked channel is shown on and cannot be moved — the academy refuses
/// it, and offering it would be a lie (§16).
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.preference, required this.enabled, required this.onChanged});

  final CategoryPreference preference;
  final bool enabled;
  final ValueChanged<CategoryPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(categoryLabel(l10n, preference.category), style: context.type.titleS),
          for (final channel in NotificationChannel.values)
            _ChannelSwitch(
              label: switch (channel) {
                NotificationChannel.app => l10n.notificationPrefsChannelApp,
                NotificationChannel.email => l10n.notificationPrefsChannelEmail,
                NotificationChannel.sms => l10n.notificationPrefsChannelSms,
              },
              value: preference.on(channel),
              enabled: enabled,
              // The academy cannot send text messages at all, and account notices stay on.
              lockedReason: switch (channel) {
                NotificationChannel.sms => l10n.notificationPrefsSmsUnavailable,
                _ when isLockedChannel(preference.category, channel) =>
                  l10n.notificationPrefsLocked,
                _ => null,
              },
              onChanged: (on) => onChanged(preference.withChannel(channel, on: on)),
            ),
        ],
      ),
    );
  }
}

class _ChannelSwitch extends StatelessWidget {
  const _ChannelSwitch({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.lockedReason,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  /// Said out loud, with a lock, when the academy will not let this be changed.
  final String? lockedReason;

  @override
  Widget build(BuildContext context) => AppSwitchRow(
    title: label,
    value: value,
    lockedReason: lockedReason,
    onChanged: enabled ? onChanged : null,
  );
}

/// A `HH:MM` time, chosen from the platform's own picker so it is never mistyped.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: '$label · $value',
      variant: AppButtonVariant.secondary,
      onPressed: enabled
          ? () async {
              final parts = value.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.tryParse(parts.first) ?? 22,
                  minute: int.tryParse(parts.last) ?? 0,
                ),
              );
              if (picked == null) return;
              final hh = picked.hour.toString().padLeft(2, '0');
              final mm = picked.minute.toString().padLeft(2, '0');
              onChanged('$hh:$mm');
            }
          : null,
    );
  }
}
