import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';

/// Shimmer shared by every skeleton below it; static under reduced motion.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(t - 1, 0),
            end: Alignment(t + 1, 0),
            colors: [c.surface3, c.surface2, c.surface3],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A block placeholder shaped like the content it stands in for.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = Radii.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surface3,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A card-shaped skeleton (cover, title, two lines).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.showMedia = true});

  final bool showMedia;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        padding: const EdgeInsets.all(Space.cardPadding),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMedia) ...[
              const SkeletonBox(height: 120, radius: Radii.md),
              const SizedBox(height: Space.s3),
            ],
            const SkeletonBox(width: 200, height: 18),
            const SizedBox(height: Space.s2),
            const SkeletonBox(height: 12),
            const SizedBox(height: Space.s2),
            const SkeletonBox(width: 140, height: 12),
          ],
        ),
      ),
    );
  }
}

/// A list of row skeletons: card-shaped rows (leading mark + two lines), the shape most of the
/// app's lists take.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Space.s4),
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: Space.s3),
              _SkeletonFrame(
                child: Row(
                  children: [
                    const SkeletonBox(width: 40, height: 40, radius: Radii.pill),
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: i.isEven ? 0.75 : 0.6,
                            child: const SkeletonBox(height: 14),
                          ),
                          const SizedBox(height: Space.s2),
                          const FractionallySizedBox(
                            widthFactor: 0.45,
                            child: SkeletonBox(height: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A detail page loading: a title block, then two content cards — padded like the page it
/// stands in for.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key, this.showMedia = false});

  /// Leads with a cover-sized block (courses, lessons).
  final bool showMedia;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMedia) ...[
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: SkeletonBox(radius: Radii.lg, height: double.infinity),
              ),
              const SizedBox(height: Space.s4),
            ],
            const FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.7,
              child: SkeletonBox(height: 26),
            ),
            const SizedBox(height: Space.s2),
            const FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.45,
              child: SkeletonBox(height: 14),
            ),
            const SizedBox(height: Space.s5),
            const _SkeletonFrame(child: _Lines(count: 4)),
            const SizedBox(height: Space.s3),
            const _SkeletonFrame(child: _Lines(count: 3)),
          ],
        ),
      ),
    );
  }
}

/// A dashboard loading: greeting, a hero card, two figures side by side, a list card.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Shimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(Space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.6,
              child: SkeletonBox(height: 30),
            ),
            SizedBox(height: Space.s5),
            _SkeletonFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 88, height: 56, radius: Radii.md),
                      SizedBox(width: Space.s3),
                      Expanded(child: _Lines(count: 2)),
                    ],
                  ),
                  SizedBox(height: Space.s4),
                  SkeletonBox(height: 44, radius: Radii.md),
                ],
              ),
            ),
            SizedBox(height: Space.s5),
            Row(
              children: [
                Expanded(child: _SkeletonFrame(child: _Lines(count: 3))),
                SizedBox(width: Space.s3),
                Expanded(child: _SkeletonFrame(child: _Lines(count: 3))),
              ],
            ),
            SizedBox(height: Space.s5),
            _SkeletonFrame(child: _Lines(count: 4)),
          ],
        ),
      ),
    );
  }
}

/// The card outline every skeleton block sits in.
class _SkeletonFrame extends StatelessWidget {
  const _SkeletonFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.cardPadding),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: Space.s2 + 2),
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: i == 0 ? 0.55 : (i.isOdd ? 0.9 : 0.7),
            child: SkeletonBox(height: i == 0 ? 16 : 12),
          ),
        ],
      ],
    );
  }
}

/// Loading wrapper (§17): nothing for the first 150 ms (fast loads never flash), then the
/// [skeleton]; after 8 s a "Still working…" line. Announced once as "Loading".
class DelayedLoading extends StatefulWidget {
  const DelayedLoading({required this.skeleton, super.key});

  final Widget skeleton;

  static const showAfter = Duration(milliseconds: 150);
  static const slowAfter = Duration(seconds: 8);

  @override
  State<DelayedLoading> createState() => _DelayedLoadingState();
}

class _DelayedLoadingState extends State<DelayedLoading> {
  bool _visible = false;
  bool _slow = false;
  late final Timer _showTimer;
  late final Timer _slowTimer;

  @override
  void initState() {
    super.initState();
    _showTimer = Timer(DelayedLoading.showAfter, () {
      if (mounted) setState(() => _visible = true);
    });
    _slowTimer = Timer(DelayedLoading.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _showTimer.cancel();
    _slowTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      liveRegion: true,
      child: !_visible
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_slow)
                  Padding(
                    padding: const EdgeInsets.all(Space.s4),
                    child: Text(
                      context.l10n.stillWorking,
                      textAlign: TextAlign.center,
                      style: context.type.bodyS.copyWith(color: context.colors.muted),
                    ),
                  ),
                // Loose, so a skeleton taller than the space left (a dashboard under the app bar
                // and bottom bar on a short phone) is clipped by its own scroll view instead of
                // overflowing, and one inside a list still sizes to its content.
                Flexible(child: ExcludeSemantics(child: widget.skeleton)),
              ],
            ),
    );
  }
}
