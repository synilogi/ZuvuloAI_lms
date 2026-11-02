import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';

/// A progress ring with the brand's halo (a soft outer ring). Animates once on first view unless
/// motion is reduced. [value] is 0–1 as the server reports it; the ring never computes progress.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    super.key,
    this.size = 56,
    this.strokeWidth,
    this.showLabel = true,
    this.tone = Tone.accent,
    this.inverse = false,
  });

  final double value;
  final double size;
  final double? strokeWidth;
  final bool showLabel;
  final Tone tone;

  /// Drawn in the on-accent colour, for a ring that sits on an accent-filled card.
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final colors = context.colors;
    final toneColors = colors.tone(tone);
    final stroke = strokeWidth ?? math.max(4.0, size / 11);
    return Semantics(
      label: context.l10n.progressPercentComplete(percent),
      value: '$percent%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: context.reduceMotion ? clamped : 0, end: clamped),
          duration: context.reduceMotion ? Duration.zero : Motion.page * 2,
          curve: Motion.enter,
          builder: (context, animated, _) => CustomPaint(
            painter: _RingPainter(
              value: animated,
              track: inverse ? colors.onAccent.withValues(alpha: 0.24) : colors.track,
              fill: inverse ? colors.onAccent : toneColors.solid,
              halo: (inverse ? colors.onAccent : toneColors.solid).withValues(alpha: 0.14),
              stroke: stroke,
            ),
            child: showLabel && size >= 40
                ? Center(
                    child: FittedBox(
                      child: Padding(
                        padding: EdgeInsets.all(stroke + 2),
                        child: Text(
                          '$percent%',
                          style: context.type.numeral.copyWith(
                            fontSize: size * 0.26,
                            color: inverse ? colors.onAccent : colors.text,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.track,
    required this.fill,
    required this.halo,
    required this.stroke,
  });

  final double value;
  final Color track;
  final Color fill;
  final Color halo;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2 - 1;
    canvas.drawCircle(
      center,
      radius + stroke / 2 + 0.5,
      Paint()
        ..color = halo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        base..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.fill != fill || old.track != track || old.stroke != stroke;
}

/// A linear meter on the same-ramp track.
class ProgressBar extends StatelessWidget {
  const ProgressBar({required this.value, super.key, this.height = 6, this.tone = Tone.accent});

  final double value;
  final double height;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    return Semantics(
      label: context.l10n.progressPercentComplete(percent),
      value: '$percent%',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: LinearProgressIndicator(
          value: clamped,
          minHeight: height,
          backgroundColor: context.colors.track,
          color: context.colors.tone(tone).solid,
        ),
      ),
    );
  }
}
