import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/session/current_user.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../media/media.dart';
import '../../application/catalog_providers.dart';

/// `/catalog/:slug/preview/:lessonId` — a lesson the academy opened to visitors. Everything else
/// shows the enrol prompt and asks the server for nothing: the catalogue route already stripped
/// the body, and this screen never requests a lesson's content on its own.
class PreviewLessonScreen extends ConsumerWidget {
  const PreviewLessonScreen({required this.slug, required this.lessonId, super.key});

  final String slug;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final course = ref.watch(catalogCourseProvider(slug));
    return UpPopScope(
      child: Scaffold(
        appBar: CommonAppBar(leading: upButton(context), title: l10n.previewTitle),
        body: AsyncView<Course>(
          value: course,
          onRetry: () => ref.invalidate(catalogCourseProvider(slug)),
          notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.catalog)),
          data: (value) {
            final lesson = value.lessons.where((l) => l.id == lessonId).firstOrNull;
            if (lesson == null) {
              return NotFoundView(
                onBack: () => GoRouter.of(context).go(AppRoutes.catalogCourse(slug)),
              );
            }
            return _PreviewBody(course: value, lesson: lesson);
          },
        ),
      ),
    );
  }
}

class _PreviewBody extends ConsumerWidget {
  const _PreviewBody({required this.course, required this.lesson});

  final Course course;
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final c = context.colors;

    if (!lesson.isPlayablePreview) {
      return StateLayout(
        icon: AppIcons.lock,
        title: l10n.previewLockedTitle,
        message: l10n.previewLockedBody,
        actionLabel: l10n.actionBack,
        onAction: () => GoRouter.of(context).go(AppRoutes.catalogCourse(course.slug)),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
        children: [
          Row(
            children: [
              LessonTypeIcon(LessonType.parse(lesson.type)),
              const SizedBox(width: Space.s2),
              const StatusBadge(StatusKind.freePreview),
            ],
          ),
          const SizedBox(height: Space.s3),
          Semantics(header: true, child: Text(lesson.title, style: context.type.titleL)),
          if (lesson.description != null && lesson.description!.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            Text(lesson.description!, style: type.bodyM.copyWith(color: c.muted)),
          ],
          const SizedBox(height: Space.s5),
          _PreviewContent(course: course, lesson: lesson),
        ],
      ),
    );
  }
}

/// What the preview shows, by lesson type. Reading and practice bodies come down with the course;
/// video and documents are files behind `GET /media/:id`, which the API serves to signed-in
/// accounts only — so a visitor is offered sign-in rather than a broken player (backend finding
/// B14, progress.md).
class _PreviewContent extends ConsumerWidget {
  const _PreviewContent({required this.course, required this.lesson});

  final Course course;
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = lesson.content;
    final signedIn = ref.watch(currentUserProvider) != null;

    final article = content?.article?.body ?? '';
    if (article.isNotEmpty) {
      return ArticleBody(body: article, onOpenLink: (url) => _open(url));
    }

    final file = content?.video?.file ?? content?.document?.file;
    if (content == null || content.isEmpty || file?.url == null) {
      return StateLayout(
        icon: AppIcons.empty,
        title: l10n.previewMissingTitle,
        message: l10n.previewMissingBody,
      );
    }
    if (!signedIn) {
      return StateLayout(
        icon: AppIcons.lock,
        title: l10n.previewSignInTitle,
        message: l10n.previewSignInBody,
        actionLabel: l10n.actionSignIn,
        onAction: () => GoRouter.of(context).go(
          Uri(
            path: AppRoutes.login,
            queryParameters: {'next': AppRoutes.catalogPreview(course.slug, lesson.id)},
          ).toString(),
        ),
      );
    }
    if (content.video != null) {
      return AppVideoPlayer(
        url: file!.url!,
        markers: [
          for (final marker in content.video!.markers)
            VideoMarker(
              position: Duration(seconds: marker.atSec),
              label: marker.title,
            ),
        ],
      );
    }
    final mediaId = file!.id;
    if (mediaId == null) {
      return StateLayout(
        icon: AppIcons.empty,
        title: l10n.previewMissingTitle,
        message: l10n.previewMissingBody,
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: AppButton(
        label: l10n.actionOpenDocument,
        icon: AppIcons.filePdf,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PdfViewerScreen(mediaId: mediaId, title: lesson.title),
          ),
        ),
      ),
    );
  }

  /// Only the `https` links the renderer already validated ever leave the app (§18).
  Future<void> _open(Uri url) async {
    if (url.scheme != 'https') return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
