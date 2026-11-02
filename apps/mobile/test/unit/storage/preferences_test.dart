import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';

void main() {
  Future<Preferences> load([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return Preferences(await SharedPreferences.getInstance());
  }

  test('defaults: system theme, motion on, nothing seen', () async {
    final prefs = await load();
    expect(prefs.themeMode, ThemeMode.system);
    expect(prefs.reducedMotion, isFalse);
    expect(prefs.textScalePreview, 1);
    expect(prefs.mobileDataNoticeSeen, isFalse);
    expect(prefs.onboardingSeen, isFalse);
    expect(prefs.lastTab('review'), isNull);
  });

  test('round-trips every preference', () async {
    final prefs = await load();
    await prefs.setThemeMode(ThemeMode.dark);
    await prefs.setReducedMotion(true);
    await prefs.setTextScalePreview(1.3);
    await prefs.setMobileDataNoticeSeen();
    await prefs.setOnboardingSeen();
    await prefs.setLastTab('review', 'overdue');
    expect(prefs.themeMode, ThemeMode.dark);
    expect(prefs.reducedMotion, isTrue);
    expect(prefs.textScalePreview, 1.3);
    expect(prefs.mobileDataNoticeSeen, isTrue);
    expect(prefs.onboardingSeen, isTrue);
    expect(prefs.lastTab('review'), 'overdue');
  });

  test('an unknown stored theme value falls back to system', () async {
    final prefs = await load({'ux.themeMode': 'sepia'});
    expect(prefs.themeMode, ThemeMode.system);
  });

  test('sign-out clears user-scoped values and keeps device settings', () async {
    final prefs = await load();
    await prefs.setThemeMode(ThemeMode.dark);
    await prefs.setLastTab('students', 'at-risk');
    await prefs.clearUserScoped();
    expect(prefs.lastTab('students'), isNull);
    expect(prefs.themeMode, ThemeMode.dark);
  });
}
