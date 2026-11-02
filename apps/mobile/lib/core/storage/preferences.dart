import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive UX preferences only (§15). Tokens and anything personal never come here — the
/// session token lives in secure storage (FLUTTER-004).
class Preferences {
  Preferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeMode = 'ux.themeMode';
  static const _reducedMotion = 'ux.reducedMotion';
  static const _textScalePreview = 'ux.textScalePreview';
  static const _mobileDataNoticeSeen = 'ux.mobileDataNoticeSeen';
  static const _onboardingSeen = 'ux.onboardingSeen';
  static const _lastTabPrefix = 'user.lastTab.';
  static const _trialOfferDismissed = 'user.trialOfferDismissed';
  static const _userScopedPrefix = 'user.';

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString(_themeMode),
    orElse: () => ThemeMode.system,
  );

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeMode, mode.name);

  /// The in-app reduced-motion switch (applied on top of the platform setting).
  bool get reducedMotion => _prefs.getBool(_reducedMotion) ?? false;

  Future<void> setReducedMotion(bool value) => _prefs.setBool(_reducedMotion, value);

  /// Text size chosen in the settings preview, as a scale factor (1.0 = system).
  double get textScalePreview => _prefs.getDouble(_textScalePreview) ?? 1;

  Future<void> setTextScalePreview(double value) => _prefs.setDouble(_textScalePreview, value);

  bool get mobileDataNoticeSeen => _prefs.getBool(_mobileDataNoticeSeen) ?? false;

  Future<void> setMobileDataNoticeSeen() => _prefs.setBool(_mobileDataNoticeSeen, true);

  bool get onboardingSeen => _prefs.getBool(_onboardingSeen) ?? false;

  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeen, true);

  /// The last selected tab/filter on a screen ([scope] names the screen).
  String? lastTab(String scope) => _prefs.getString('$_lastTabPrefix$scope');

  Future<void> setLastTab(String scope, String value) =>
      _prefs.setString('$_lastTabPrefix$scope', value);

  /// Whether the admin closed the dashboard's free-trial card. Person-scoped: forgotten on sign-out.
  bool get trialOfferDismissed => _prefs.getBool(_trialOfferDismissed) ?? false;

  Future<void> setTrialOfferDismissed() => _prefs.setBool(_trialOfferDismissed, true);

  /// Forgets everything tied to the signed-in person (last tabs and filters); device-level UX
  /// settings (theme, motion) stay. Called on sign-out and user change (§8.4).
  Future<void> clearUserScoped() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_userScopedPrefix)).toList()) {
      await _prefs.remove(key);
    }
  }
}

/// Overridden by `bootstrap` with the loaded instance (and by tests).
final preferencesProvider = Provider<Preferences>(
  (ref) => throw StateError('preferencesProvider must be overridden at start-up'),
);
