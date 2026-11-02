import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_auth_headers.dart';
import '../../../core/media/media_cache.dart';
import '../../../core/media/media_url_resolver.dart';
import '../../../core/theme/theme.dart';
import '../../session/current_user.dart';

/// The backend's `CoverMotif` (`packages/domain/src/catalog.ts`); [unknown] for values added later.
enum CoverMotif {
  orbits,
  houses,
  nakshatra,
  ecliptic,
  unknown;

  static CoverMotif parse(String? value) =>
      CoverMotif.values.firstWhere((m) => m.name == value, orElse: () => CoverMotif.unknown);
}

/// Generated course artwork, ported from the web's `CourseCover.tsx`: fine-line geometry from the
/// tradition on a soft accent ground, 16:10 (2:1 on catalogue cards, via [aspectRatio]).
/// Decorative unless [semanticLabel] is given.
///
/// With an [imageUrl] (the course's uploaded cover), the image is laid over the motif in the same
/// box: the motif shows while it loads and stays when there is none or it fails, so the layout
/// never moves.
class CourseCover extends StatelessWidget {
  const CourseCover({
    required this.motif,
    super.key,
    this.imageUrl,
    this.semanticLabel,
    this.radius = Radii.md,
    this.aspectRatio = 16 / 10,
    this.topOnly = false,
  });

  final CoverMotif motif;

  /// The course's `coverImageUrl` (`/catalog/covers/<id>`); null or empty draws only the motif.
  final String? imageUrl;
  final String? semanticLabel;
  final double radius;
  final double aspectRatio;

  /// Rounds only the top corners — a cover that heads a card, flush with its body.
  final bool topOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = imageUrl;
    final motifArt = ColoredBox(
      color: c.accentSoft,
      child: CustomPaint(
        painter: _CoverPainter(motif: motif, line: c.accentInk, dot: c.accent),
      ),
    );
    final art = ClipRRect(
      borderRadius: topOnly
          ? BorderRadius.vertical(top: Radius.circular(radius))
          : BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: url == null || url.isEmpty
            ? motifArt
            : Stack(
                fit: StackFit.expand,
                children: [
                  motifArt,
                  _CoverPhoto(url: url),
                ],
              ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: art);
    return Semantics(label: semanticLabel, image: true, excludeSemantics: true, child: art);
  }
}

/// An uploaded cover, fetched from the API host only (the resolver refuses any other, so the token
/// is never sent elsewhere). A signed-in request carries the session, which decides the academy and
/// lets staff and enrolled learners see a cover that is not in the catalog; images are cached per
/// person (§13). Loading and failure draw nothing, leaving the motif beneath.
class _CoverPhoto extends ConsumerWidget {
  const _CoverPhoto({required this.url});

  final String url;

  /// The image cache's key when nobody is signed in (the public catalogue).
  static const _visitor = 'visitor';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(mediaUrlResolverProvider).resolve(url);
    final headers = ref.watch(mediaAuthHeadersProvider).value;
    if (resolved == null || headers == null) return const SizedBox.shrink();
    final userId = ref.watch(currentUserProvider)?.id;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Decode at the size shown, not the upload's full resolution.
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()
            : null;
        return CachedNetworkImage(
          imageUrl: resolved.toString(),
          httpHeaders: headers,
          cacheManager: ref.watch(mediaCacheProvider).imagesFor(userId ?? _visitor),
          fit: BoxFit.cover,
          memCacheWidth: width,
          fadeInDuration: context.reduceMotion ? Duration.zero : Motion.standard,
          placeholder: (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, _) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter({required this.motif, required this.line, required this.dot});

  final CoverMotif motif;
  final Color line;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    // The web draws in a 160×100 viewBox with `meet`; scale uniformly and centre.
    final scale = math.min(size.width / 160, size.height / 100);
    canvas
      ..save()
      ..translate((size.width - 160 * scale) / 2, (size.height - 100 * scale) / 2)
      ..scale(scale);
    final strong = Paint()
      ..color = line.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 / scale;
    final faint = Paint()
      ..color = line.withValues(alpha: 0.42 * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 / scale;
    final fill = Paint()..color = dot;

    switch (motif) {
      case CoverMotif.houses:
        const x = 52.0, y = 12.0, s = 76.0;
        canvas
          ..drawRect(const Rect.fromLTWH(x, y, s, s), strong)
          ..drawLine(const Offset(x, y), const Offset(x + s, y + s), strong)
          ..drawLine(const Offset(x + s, y), const Offset(x, y + s), strong)
          ..drawPath(
            Path()
              ..moveTo(x + s / 2, y)
              ..lineTo(x + s, y + s / 2)
              ..lineTo(x + s / 2, y + s)
              ..lineTo(x, y + s / 2)
              ..close(),
            strong,
          )
          ..drawCircle(const Offset(x + s / 2, y + s / 4), 2.2, fill);
      case CoverMotif.nakshatra:
        const cx = 112.0, cy = 58.0, r = 34.0;
        canvas
          ..drawCircle(const Offset(cx, cy), r, strong)
          ..drawCircle(const Offset(cx, cy), r - 10, faint);
        for (var i = 0; i < 27; i++) {
          final a = i / 27 * math.pi * 2 - math.pi / 2;
          canvas.drawLine(
            Offset(cx + (r - 4) * math.cos(a), cy + (r - 4) * math.sin(a)),
            Offset(cx + r * math.cos(a), cy + r * math.sin(a)),
            strong,
          );
        }
        canvas.drawCircle(
          Offset(cx + (r - 10) * math.cos(-0.9), cy + (r - 10) * math.sin(-0.9)),
          2.4,
          fill,
        );
      case CoverMotif.orbits:
      case CoverMotif.unknown:
        const centre = Offset(40, 82);
        canvas
          ..drawCircle(centre, 22, strong)
          ..drawCircle(centre, 44, faint)
          ..drawCircle(centre, 70, strong)
          ..drawCircle(centre, 98, faint)
          ..drawCircle(Offset(40 + 70 * math.cos(-0.72), 82 + 70 * math.sin(-0.72)), 2.6, fill);
      case CoverMotif.ecliptic:
        void ellipse(double degrees, Paint paint) {
          canvas
            ..save()
            ..translate(80, 52)
            ..rotate(degrees * math.pi / 180)
            ..drawOval(Rect.fromCenter(center: Offset.zero, width: 140, height: 40), paint)
            ..restore();
        }
        ellipse(-12, strong);
        ellipse(12, faint);
        canvas
          ..drawLine(const Offset(4, 52), const Offset(156, 52), faint)
          ..drawCircle(const Offset(126, 42), 2.4, fill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.motif != motif || old.line != line || old.dot != dot;
}

/// A small label laid over a cover image (the course's level): a white pill that reads on any
/// motif.
class CoverBadge extends StatelessWidget {
  const CoverBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s2 + 2, vertical: 3),
        child: Text(label, style: context.type.micro.copyWith(color: c.accentInk)),
      ),
    );
  }
}
