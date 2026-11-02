import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_typography.dart';
import 'tokens.dart';

/// Builds the Material 3 themes from the Celestial Ink tokens (§22.8).
abstract final class AppTheme {
  static ThemeData light() => _build(Tokens.light, Brightness.light);

  static ThemeData dark() => _build(Tokens.dark, Brightness.dark);

  static ThemeData _build(Palette p, Brightness brightness) {
    final colors = AppColors(p, brightness: brightness);
    final type = AppTypography.withColor(p.text);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.accentInk,
      secondary: p.info,
      onSecondary: p.onAccent,
      secondaryContainer: p.infoSoft,
      onSecondaryContainer: p.infoInk,
      tertiary: p.warn,
      onTertiary: p.text,
      tertiaryContainer: p.warnSoft,
      onTertiaryContainer: p.warnInk,
      error: p.danger,
      onError: p.onAccent,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.dangerInk,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface2,
      surfaceContainerHigh: p.surface2,
      surfaceContainerHighest: p.surface3,
      outline: p.border,
      outlineVariant: p.border,
      shadow: p.shadow,
      scrim: p.scrim,
      inverseSurface: p.text,
      onInverseSurface: p.surface,
      inversePrimary: p.accentSoft,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      displayLarge: type.displayL,
      displayMedium: type.displayM,
      displaySmall: type.titleL,
      headlineLarge: type.displayM,
      headlineMedium: type.titleL,
      headlineSmall: type.titleL,
      titleLarge: type.titleL,
      titleMedium: type.titleM,
      titleSmall: type.titleS,
      bodyLarge: type.bodyL,
      bodyMedium: type.bodyM,
      bodySmall: type.bodyS,
      labelLarge: type.label,
      labelMedium: type.bodyS.copyWith(fontWeight: FontWeight.w600),
      labelSmall: type.caption,
    );

    // Boxed fields: a white box with its whole edge drawn — faint at rest (≥ 3:1 against the page,
    // so the field reads as something to fill in), the accent when focused, danger on an error.
    // The label sits above the box (FieldLabel), not inside it.
    OutlineInputBorder field(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: color, width: width),
    );
    final dark = brightness == Brightness.dark;
    // Status bar icons follow the page; the gesture/navigation bar matches the bottom bar.
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: brightness,
      systemNavigationBarColor: p.surface,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: colors.bgOpaque,
      fontFamily: FontFamilies.body,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: [colors, type, AppShadows.from(p, brightness)],
      // CommonAppBar is the one app bar; this theme is its fallback for framework-built ones
      // (the licence page). Transparent at rest so it is the page, white once content scrolls.
      appBarTheme: AppBarTheme(
        backgroundColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.scrolledUnder) ? colors.appBarScrolled : colors.appBar,
        ),
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        shadowColor: p.shadow.withValues(alpha: dark ? 0.4 : 0.14),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        toolbarHeight: Sizes.appBar,
        titleSpacing: Space.s4,
        titleTextStyle: type.titleL,
        iconTheme: IconThemeData(color: p.text, size: IconSizes.lg),
        actionsIconTheme: IconThemeData(color: p.text, size: IconSizes.lg),
        systemOverlayStyle: overlay,
      ),
      // Material's own back arrow, drawn with the app's icon family.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
        closeButtonIconBuilder: (_) => const PhosphorIcon(PhosphorIconsRegular.x),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.text, size: IconSizes.lg),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // A disabled field is the quieter tint, with no edge: it is not something to fill in.
        fillColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? p.surface2 : p.surface,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3 + 2),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.error)
              ? p.dangerInk
              : s.contains(WidgetState.focused)
              ? p.accent
              : p.muted,
        ),
        border: field(colors.faintEdge),
        enabledBorder: field(colors.faintEdge),
        focusedBorder: field(p.accent, 2),
        errorBorder: field(p.danger),
        focusedErrorBorder: field(p.danger, 2),
        disabledBorder: field(Colors.transparent),
        labelStyle: type.bodyM.copyWith(color: p.muted),
        floatingLabelStyle: type.bodyS.copyWith(color: p.accentInk),
        helperStyle: type.caption.copyWith(color: p.muted),
        errorStyle: type.caption.copyWith(color: p.dangerInk),
        hintStyle: type.bodyM.copyWith(color: p.muted),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: dark ? BorderSide(color: p.border) : BorderSide.none,
        ),
      ),
      // Material chips (multi-choice filters, reminder offsets) match AppFilterChip: a solid accent
      // fill when selected, surface and hairline otherwise.
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.accent,
        disabledColor: p.surface2,
        labelStyle: type.label.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onAccent : p.text,
          ),
        ),
        secondaryLabelStyle: type.label.copyWith(color: p.onAccent),
        checkmarkColor: p.onAccent,
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? p.accent : p.border),
        ),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: Space.s2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xxl)),
        titleTextStyle: type.titleL,
        contentTextStyle: type.bodyM,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: p.scrim,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: type.bodyM.copyWith(color: p.surface),
        actionTextColor: p.accentSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        height: Sizes.navBar,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accentSoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelPadding: const EdgeInsets.only(top: 2),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => type.micro.copyWith(
            color: states.contains(WidgetState.selected) ? p.accentInk : p.muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: IconSizes.lg,
            color: states.contains(WidgetState.selected) ? p.accentInk : p.muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.accentSoft,
        selectedIconTheme: IconThemeData(color: p.accentInk),
        unselectedIconTheme: IconThemeData(color: p.muted),
        selectedLabelTextStyle: type.caption.copyWith(
          color: p.accentInk,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: type.caption.copyWith(color: p.muted),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(Space.minTap, Sizes.buttonMd)),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          textStyle: WidgetStatePropertyAll(type.label),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accentSoft : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return p.faint;
            return s.contains(WidgetState.selected) ? p.accentInk : p.muted;
          }),
          overlayColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.08)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.accentInk,
        textColor: p.text,
        titleTextStyle: type.titleS,
        subtitleTextStyle: type.bodyS.copyWith(color: p.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4),
        minVerticalPadding: Space.s2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentInk,
          textStyle: type.label,
          minimumSize: const Size(Space.minTap, Space.minTap),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: type.bodyM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: p.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(Radii.sm)),
        textStyle: type.caption.copyWith(color: p.surface),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.accentInk,
        unselectedLabelColor: p.muted,
        indicatorColor: p.accent,
        labelStyle: type.label,
        unselectedLabelStyle: type.label,
        dividerColor: p.border,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) {
          final on = s.contains(WidgetState.selected);
          if (s.contains(WidgetState.disabled)) {
            return on ? Color.alphaBlend(p.accent.withValues(alpha: 0.38), p.surface) : p.surface2;
          }
          return on ? p.accent : p.surface3;
        }),
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return p.surface;
          return s.contains(WidgetState.selected) ? p.onAccent : p.surface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return p.border;
          return s.contains(WidgetState.selected) ? p.accent : colors.borderStrong;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onAccent),
        side: BorderSide(color: p.muted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xs)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.muted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: colors.track,
        circularTrackColor: colors.track,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
