import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_typography.dart';

/// Token access for widgets: `context.colors.accent`, `context.type.titleM`.
extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  AppTypography get type => Theme.of(this).extension<AppTypography>()!;

  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;

  /// True when the platform or the in-app setting asks for reduced motion (§19). The in-app
  /// switch applies by overriding `MediaQuery.disableAnimations` above the app.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
