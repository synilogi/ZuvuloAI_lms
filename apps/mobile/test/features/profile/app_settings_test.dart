import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/profile/profile.dart';

/// A container over real `SharedPreferences` (mocked in memory), so what is written is what a
/// later start-up would read.
Future<({ProviderContainer container, Preferences prefs})> _scope([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = Preferences(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [preferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return (container: container, prefs: prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app starts on the device\'s own settings, matching the phone by default', () async {
    final scope = await _scope();

    final settings = scope.container.read(appSettingsProvider);

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.reducedMotion, isFalse);
    expect(settings.textScale, 1);
  });

  test('a change applies at once and is what the next start-up reads', () async {
    final scope = await _scope();
    final controller = scope.container.read(appSettingsProvider.notifier);

    await controller.setThemeMode(ThemeMode.dark);
    await controller.setReducedMotion(on: true);
    await controller.setTextScale(1.3);

    // On screen straight away.
    final settings = scope.container.read(appSettingsProvider);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.reducedMotion, isTrue);
    expect(settings.textScale, 1.3);

    // And on the device: a fresh Preferences over the same store reads the same.
    expect(scope.prefs.themeMode, ThemeMode.dark);
    expect(scope.prefs.reducedMotion, isTrue);
    expect(scope.prefs.textScalePreview, 1.3);
  });

  test('what was set before is what the app comes back to', () async {
    final scope = await _scope({
      'ux.themeMode': 'light',
      'ux.reducedMotion': true,
      'ux.textScalePreview': 0.9,
    });

    final settings = scope.container.read(appSettingsProvider);

    expect(settings.themeMode, ThemeMode.light);
    expect(settings.reducedMotion, isTrue);
    expect(settings.textScale, 0.9);
  });

  test('signing out forgets what is the account\'s, and keeps what is the device\'s', () async {
    final scope = await _scope({
      'ux.themeMode': 'dark',
      'ux.reducedMotion': true,
      'user.lastTab.myLearning': 'completed',
    });

    await scope.prefs.clearUserScoped();

    // The device's own choices survive; anything tied to the person is gone (§8.4).
    expect(scope.prefs.themeMode, ThemeMode.dark);
    expect(scope.prefs.reducedMotion, isTrue);
    expect(scope.prefs.lastTab('myLearning'), isNull);
  });

  test('the text-size preview offers a few steps, all of them readable', () {
    expect(textScaleChoices, contains(1.0));
    expect(textScaleChoices.first, greaterThanOrEqualTo(0.85));
    expect(textScaleChoices.last, lessThanOrEqualTo(1.5));
    expect(textScaleChoices, orderedEquals([...textScaleChoices]..sort()));
  });
}
