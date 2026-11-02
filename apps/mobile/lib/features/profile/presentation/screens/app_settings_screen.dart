import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/profile_controller.dart';

/// `/profile/settings` (and the staff one) — how the app behaves on **this device**. None of it
/// reaches the academy, and all of it survives a sign-out (§8.4). A shell body.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
      children: [
        SectionHeader(title: l10n.settingsAppearanceTitle),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.s2),
          child: AppRadioGroup<ThemeMode>(
            label: l10n.settingsAppearanceTitle,
            showLabel: false,
            value: settings.themeMode,
            options: [
              RadioOption(ThemeMode.system, l10n.settingsThemeSystem),
              RadioOption(ThemeMode.light, l10n.settingsThemeLight),
              RadioOption(ThemeMode.dark, l10n.settingsThemeDark),
            ],
            onChanged: controller.setThemeMode,
          ),
        ),
        const SizedBox(height: Space.s3),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.s2),
          child: AppSwitchRow(
            title: l10n.settingsReducedMotion,
            subtitle: l10n.settingsReducedMotionBody,
            value: settings.reducedMotion,
            onChanged: (on) => controller.setReducedMotion(on: on),
          ),
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(title: l10n.settingsTextSizeTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.settingsTextSizeBody, style: context.type.bodyS.copyWith(color: c.muted)),
              const SizedBox(height: Space.s3),
              FilterChipBar<double>(
                padding: EdgeInsets.zero,
                options: [
                  for (final scale in textScaleChoices)
                    FilterOption(scale, '${(scale * 100).round()}%'),
                ],
                selected: settings.textScale,
                onSelected: controller.setTextScale,
              ),
              const SizedBox(height: Space.s3),
              // The sample is drawn at the chosen size, whatever the rest of the screen is at.
              MediaQuery.withClampedTextScaling(
                minScaleFactor: settings.textScale,
                maxScaleFactor: settings.textScale,
                child: Text(l10n.settingsTextSizeSample, style: context.type.bodyL),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(title: l10n.settingsStorageTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsClearImageCacheBody,
                style: context.type.bodyS.copyWith(color: c.muted),
              ),
              const SizedBox(height: Space.s3),
              AppButton(
                label: l10n.settingsClearImageCache,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await ref.read(clearImageCacheProvider)();
                  if (context.mounted) {
                    showAppSnackbar(context, l10n.settingsImageCacheCleared);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
