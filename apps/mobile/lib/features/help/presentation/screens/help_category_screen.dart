import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/help_providers.dart';
import '../widgets/help_widgets.dart';

/// `/help/:categoryId` — every article in one topic that this audience may read.
class HelpCategoryScreen extends ConsumerWidget {
  const HelpCategoryScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = HelpArticleQuery(categoryId: categoryId);
    final name = ref
        .watch(helpCategoriesProvider)
        .value
        ?.where((c) => c.category.id == categoryId)
        .map((c) => c.category.name)
        .firstOrNull;

    return UpPopScope(
      child: Scaffold(
        appBar: CommonAppBar(leading: upButton(context), title: name ?? l10n.helpTitle),
        body: SafeArea(
          child: AsyncView<List<HelpArticleListItem>>(
            value: ref.watch(helpArticlesProvider(query)),
            onRetry: () => ref.invalidate(helpArticlesProvider(query)),
            data: (items) => items.isEmpty
                ? EmptyState(title: l10n.helpEmptyTitle, message: l10n.helpEmptyBody)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
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
          ),
        ),
      ),
    );
  }
}
