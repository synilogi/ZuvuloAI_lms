import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/help_providers.dart';
import '../widgets/help_widgets.dart';

/// `/help/article/:slug` — one article, rendered from the tiny markup subset the editor writes.
/// An article this audience may not read answers 404, exactly like a missing slug.
class HelpArticleScreen extends ConsumerWidget {
  const HelpArticleScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(helpArticleProvider(slug));
    return UpPopScope(
      child: Scaffold(
        appBar: CommonAppBar(leading: upButton(context), title: l10n.helpTitle),
        body: SafeArea(
          child: AsyncView<HelpArticleDetail>(
            value: detail,
            onRetry: () => ref.invalidate(helpArticleProvider(slug)),
            notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.help)),
            data: (value) => _Article(detail: value),
          ),
        ),
      ),
    );
  }
}

class _Article extends StatelessWidget {
  const _Article({required this.detail});

  final HelpArticleDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final article = detail.article;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.readingMeasure),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(article.title, style: context.type.titleL)),
              const SizedBox(height: Space.s2),
              HelpArticleMeta(article: article, categoryName: detail.categoryName),
              if (article.summary.isNotEmpty) ...[
                const SizedBox(height: Space.s3),
                Text(
                  article.summary,
                  style: context.type.bodyL.copyWith(color: context.colors.muted),
                ),
              ],
              const SizedBox(height: Space.s5),
              ArticleBody(body: article.body, onOpenLink: _open),
            ],
          ),
        ),
        if (detail.related.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(title: l10n.helpRelatedTitle),
          GroupedList(
            children: [
              for (final item in detail.related)
                HelpArticleTile(
                  item: item,
                  onTap: () => GoRouter.of(context).go(AppRoutes.helpArticle(item.article.slug)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Help links leave the app only when they are absolute `https` — the renderer has already
  /// refused anything else (§18).
  Future<void> _open(Uri url) async {
    if (url.scheme != 'https') return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
