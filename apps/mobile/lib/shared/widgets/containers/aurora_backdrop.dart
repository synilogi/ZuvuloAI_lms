import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// A light, colourful ground for the app's doors (welcome, sign in, create an account): the page
/// colour with soft glows of the brand's hues drifting in from the edges, like watercolour on
/// paper. The glows sit at the edges and fade long before the middle, so text and fields over it
/// keep their full contrast; in dark mode they are much fainter.
class AuroraBackdrop extends StatelessWidget {
  const AuroraBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // How strongly each glow shows, scaled down in dark mode where colour reads louder.
    final strength = dark ? 0.45 : 1.0;
    final glows = [
      (Hue.violet, const Alignment(-1.1, -1.0), 1.1, 0.30),
      (Hue.blue, const Alignment(1.2, -0.75), 0.95, 0.24),
      (Hue.pink, const Alignment(1.25, 0.25), 0.75, 0.14),
      (Hue.green, const Alignment(-1.2, 0.85), 1.0, 0.18),
      (Hue.orange, const Alignment(0.9, 1.15), 0.85, 0.14),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(color: dark ? c.bgOpaque : c.surface),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final (hue, center, radius, alpha) in glows)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: center,
                            radius: radius,
                            colors: [
                              c.hue(hue).solid.withValues(alpha: alpha * strength),
                              c.hue(hue).solid.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
