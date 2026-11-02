import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_cache.dart';
import '../../../core/storage/preferences.dart';
import '../../../shared/domain/activity.dart';
import '../data/activity_api.dart';

/// What the profile screens read (§26).
export '../../../shared/domain/activity.dart';

/// The learner's own week and what they have been doing. Learner-only: the route refuses anyone
/// else, so the screen asks for it only when a learner is signed in.
final activityProvider = FutureProvider<LearningActivity>(
  (ref) => ref.watch(activityApiProvider).activity(),
  isAutoDispose: true,
);

/// How the app itself behaves. These are the device's, not the academy's: they are kept on the
/// device and survive a sign-out (§8.4).
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reducedMotion = false,
    this.textScale = 1,
  });

  final ThemeMode themeMode;

  /// On top of the platform's own setting — never instead of it.
  final bool reducedMotion;

  /// A preview scale for text. The system setting is what really decides; this is the app's own
  /// multiplier on top, so someone can try a size before changing their phone's.
  final double textScale;

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.reducedMotion == reducedMotion &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(themeMode, reducedMotion, textScale);
}

/// The smallest and largest the preview offers; the phone's own setting can go further.
const textScaleChoices = [0.9, 1.0, 1.15, 1.3];

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(preferencesProvider);
    return AppSettings(
      themeMode: prefs.themeMode,
      reducedMotion: prefs.reducedMotion,
      textScale: prefs.textScalePreview,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(
      themeMode: mode,
      reducedMotion: state.reducedMotion,
      textScale: state.textScale,
    );
    await ref.read(preferencesProvider).setThemeMode(mode);
  }

  Future<void> setReducedMotion({required bool on}) async {
    state = AppSettings(themeMode: state.themeMode, reducedMotion: on, textScale: state.textScale);
    await ref.read(preferencesProvider).setReducedMotion(on);
  }

  Future<void> setTextScale(double scale) async {
    state = AppSettings(
      themeMode: state.themeMode,
      reducedMotion: state.reducedMotion,
      textScale: scale,
    );
    await ref.read(preferencesProvider).setTextScalePreview(scale);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

/// Empties this device's own media cache — the same store sign-out purges (§8.4). Nothing leaves
/// the phone and nothing on the academy's side changes: it is disk space, not data.
typedef ClearImageCache = Future<void> Function();

final clearImageCacheProvider = Provider<ClearImageCache>(
  (ref) =>
      () => ref.read(mediaCacheProvider).purge(),
);
