import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/platform/support.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/help_providers.dart';
import '../widgets/help_widgets.dart';

/// `/help` — the knowledge base a visitor and a signed-in person share. What is offered follows
/// the audience the server is asked for, never a filter applied here. Inside a shell (a staff
/// member's `/staff/help`) the shell draws the app bar, so the hub is only its body.
class HelpHubScreen extends ConsumerWidget {
  const HelpHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final search = ref.watch(helpSearchProvider);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.s4),
          child: AppSearchField(
            hintText: l10n.helpSearchHint,
            onChanged: (q) => ref.read(helpSearchProvider.notifier).set(q),
          ),
        ),
        Expanded(child: search.isEmpty ? const _HelpHome() : _HelpSearchResults(query: search)),
      ],
    );
    final inShell = context.getInheritedWidgetOfExactType<UpNavigation>() != null;
    if (inShell) return body;
    return UpPopScope(
      fallback: AppRoutes.welcome,
      child: Scaffold(
        appBar: CommonAppBar(
          leading: upButton(context, fallback: AppRoutes.welcome),
          title: l10n.helpTitle,
        ),
        body: SafeArea(child: body),
      ),
    );
  }
}

class _HelpHome extends ConsumerWidget {
  const _HelpHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(helpCategoriesProvider);
    const query = HelpArticleQuery();
    final articles = ref.watch(helpArticlesProvider(query));

    return AsyncView<List<HelpCategorySummary>>(
      value: categories,
      onRetry: () {
        ref.invalidate(helpCategoriesProvider);
        ref.invalidate(helpArticlesProvider(query));
      },
      data: (topics) {
        final popular = [
          for (final item in articles.value ?? const <HelpArticleListItem>[])
            if (item.article.popular) item,
        ];
        if (topics.isEmpty && popular.isEmpty) {
          return EmptyState(title: l10n.helpEmptyTitle, message: l10n.helpEmptyBody);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
          children: [
            if (popular.isNotEmpty) ...[
              SectionHeader(title: l10n.helpPopularTitle),
              GroupedList(
                children: [
                  for (final item in popular)
                    HelpArticleTile(
                      item: item,
                      onTap: () =>
                          GoRouter.of(context).go(AppRoutes.helpArticle(item.article.slug)),
                    ),
                ],
              ),
              const SizedBox(height: Space.sectionGap),
            ],
            if (topics.isNotEmpty) ...[
              SectionHeader(title: l10n.helpTopicsTitle),
              GroupedList(
                children: [
                  for (final topic in topics)
                    HelpCategoryTile(
                      summary: topic,
                      onTap: () =>
                          GoRouter.of(context).go(AppRoutes.helpCategory(topic.category.id)),
                    ),
                ],
              ),
              const SizedBox(height: Space.sectionGap),
            ],
            // A person signed out — or unable to sign in — still has someone to write to.
            GroupedList(
              children: [
                AppListTile(
                  title: l10n.profileContactSupport,
                  subtitle: kSupportEmail,
                  leading: AppIcon(AppIcons.email, color: context.colors.muted),
                  showChevron: true,
                  onTap: () => ref.read(openExternalLinkProvider)(
                    supportEmailLink(subject: l10n.supportEmailSubject),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HelpSearchResults extends ConsumerWidget {
  const _HelpSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = HelpArticleQuery(search: query);
    return AsyncView<List<HelpArticleListItem>>(
      value: ref.watch(helpArticlesProvider(request)),
      onRetry: () => ref.invalidate(helpArticlesProvider(request)),
      data: (items) => items.isEmpty
          ? EmptyState.noMatches(
              onClearFilters: () => ref.read(helpSearchProvider.notifier).set(''),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
              children: [
                GroupedList(
                  children: [
                    for (final item in items)
                      HelpArticleTile(
                        item: item,
                        onTap: () =>
                            GoRouter.of(context).go(AppRoutes.helpArticle(item.article.slug)),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
