import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_cache.dart';
import '../../../core/media/media_url_resolver.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/session/current_user.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/media_auth.dart';

/// An image stored behind the API's bearer auth (`GET /media/:id`): no signed or public URLs
/// exist, so every request carries the header and the disk cache is keyed to the signed-in person
/// (§13). [fallbackName] draws initials when there is nothing to show.
class AuthImage extends ConsumerWidget {
  const AuthImage({
    required this.url,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    this.fallbackName,
  });

  /// The `/media/<id>` path the API returned.
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final String? fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(mediaUrlResolverProvider).resolve(url);
    final userId = ref.watch(currentUserProvider)?.id;
    final headers = ref.watch(mediaAuthHeadersProvider).value;

    Widget content;
    if (resolved == null || userId == null) {
      content = _fallback(context);
    } else if (headers == null) {
      content = _skeleton();
    } else {
      content = CachedNetworkImage(
        imageUrl: resolved.toString(),
        httpHeaders: headers,
        cacheManager: ref.watch(mediaCacheProvider).imagesFor(userId),
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: context.reduceMotion ? Duration.zero : Motion.standard,
        placeholder: (_, _) => _skeleton(),
        errorWidget: (_, _, _) => _fallback(context),
      );
    }

    final clipped = borderRadius == null
        ? content
        : ClipRRect(borderRadius: borderRadius!, child: content);
    return semanticLabel == null
        ? ExcludeSemantics(child: clipped)
        : Semantics(label: semanticLabel, image: true, excludeSemantics: true, child: clipped);
  }

  Widget _skeleton() =>
      SkeletonBox(width: width, height: height ?? 80, radius: borderRadius?.topLeft.x ?? Radii.md);

  Widget _fallback(BuildContext context) {
    if (fallbackName != null) {
      return AvatarInitials(name: fallbackName!, size: width ?? height ?? 40);
    }
    return Container(
      width: width,
      height: height,
      color: context.colors.surface2,
      alignment: Alignment.center,
      child: AppIcon(AppIcons.fileImage, color: context.colors.faint),
    );
  }
}
