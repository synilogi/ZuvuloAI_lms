import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';

/// The one app bar (§5.2). Every screen that has a bar uses this, so height, colours, title type,
/// icon size, spacing and status-bar styling are the same everywhere; screens differ only through
/// these parameters.
///
/// - [title] (or [titleWidget]) with an optional [subtitle] line beneath it.
/// - Leading: [leading] when given; otherwise a back arrow when [onBack] is set, or when the route
///   can pop and [automaticallyImplyLeading] allows it (Material's `BackButton`, which a page's
///   `PopScope` still guards).
/// - [actions] on the right, spaced to the bar's edge.
/// - [bottom] for a tab strip or a progress line.
/// - [foregroundColor]/[backgroundColor] only for full-bleed media screens that sit on a dark
///   ground; everything else keeps the page's own colours.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.actions = const [],
    this.bottom,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.leadingWidth,
  });

  final String? title;

  /// Replaces [title] when the title is not plain text.
  final Widget? titleWidget;

  /// A quieter second line under the title (a greeting's prompt, a count, a course name).
  final String? subtitle;

  /// Replaces the back arrow (an avatar on a home page — pass its [leadingWidth] too).
  final Widget? leading;

  /// Shows a back arrow that runs this instead of popping.
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? leadingWidth;

  double get _toolbarHeight => subtitle != null ? Sizes.appBarProfile : Sizes.appBar;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final fg = foregroundColor ?? c.text;

    Widget? heading;
    if (titleWidget != null || title != null) {
      final main =
          titleWidget ??
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.titleL.copyWith(color: fg),
          );
      heading = subtitle == null
          ? main
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                main,
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.caption.copyWith(color: foregroundColor ?? c.muted),
                ),
              ],
            );
      heading = Semantics(header: true, child: heading);
    }

    final lead = leading ?? (onBack == null ? null : BackButton(onPressed: onBack));

    return AppBar(
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: lead,
      leadingWidth: leadingWidth,
      // A wide leading (an avatar on the gutter) brings its own gap; otherwise Material's spacing.
      titleSpacing: leadingWidth == null ? Space.s4 : 0,
      title: heading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      iconTheme: foregroundColor == null
          ? null
          : IconThemeData(color: foregroundColor, size: IconSizes.lg),
      actionsIconTheme: foregroundColor == null
          ? null
          : IconThemeData(color: foregroundColor, size: IconSizes.lg),
      actions: actions.isEmpty ? null : [...actions, const SizedBox(width: Space.s2)],
      bottom: bottom,
    );
  }
}

/// The page ground beneath every route (painted once, above the router, by the app's builder).
/// Scaffolds are 90 % white over it, so its soft glow shows through faintly — the same on every
/// screen without any screen painting it. It also sets the system bars for screens that have no
/// app bar of their own (welcome, splash); an app bar's own style still wins beneath it.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overlay = Theme.of(context).appBarTheme.systemOverlayStyle;
    final ground = DecoratedBox(
      decoration: BoxDecoration(
        color: c.ground,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [c.groundGlow, c.ground, c.ground],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: child,
    );
    if (overlay == null) return ground;
    return AnnotatedRegion<SystemUiOverlayStyle>(value: overlay, child: ground);
  }
}
