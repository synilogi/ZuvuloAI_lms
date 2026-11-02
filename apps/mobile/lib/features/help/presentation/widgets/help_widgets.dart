import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/help_providers.dart';

/// The glyph a help category carries, from the backend's closed icon set.
IconData helpCategoryIcon(HelpCategoryIcon icon) => switch (icon) {
  HelpCategoryIcon.rocket => AppIcons.rocket,
  HelpCategoryIcon.book => AppIcons.courses,
  HelpCategoryIcon.clipboard => AppIcons.review,
  HelpCategoryIcon.video => AppIcons.live,
  HelpCategoryIcon.certificate => AppIcons.certificate,
  HelpCategoryIcon.chart => AppIcons.reports,
  HelpCategoryIcon.gear => AppIcons.settings,
  HelpCategoryIcon.users => AppIcons.people,
  HelpCategoryIcon.unknown => AppIcons.help,
};

/// A topic on the help hub.
class HelpCategoryTile extends StatelessWidget {
  const HelpCategoryTile({required this.summary, required this.onTap, super.key});

  final HelpCategorySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppListTile(
      title: summary.category.name,
      subtitle: summary.category.description,
      leading: AppIcon(helpCategoryIcon(summary.category.icon), color: context.colors.accentInk),
      trailing: Text(
        l10n.helpArticleCount(summary.articleCount),
        style: context.type.caption.copyWith(color: context.colors.muted),
      ),
      showChevron: true,
      onTap: onTap,
    );
  }
}

/// An article in a list: title, one-line summary and how long it takes to read.
class HelpArticleTile extends StatelessWidget {
  const HelpArticleTile({required this.item, required this.onTap, super.key});

  final HelpArticleListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppListTile(
      title: item.article.title,
      subtitle: item.article.summary,
      meta: item.article.readMinutes > 0 ? l10n.helpReadMinutes(item.article.readMinutes) : null,
      showChevron: true,
      onTap: onTap,
    );
  }
}

/// "Courses & lessons · 2 min read · Updated 4 Sep 2026".
class HelpArticleMeta extends StatelessWidget {
  const HelpArticleMeta({required this.article, required this.categoryName, super.key});

  final HelpArticle article;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = [
      if (categoryName.isNotEmpty) categoryName,
      if (article.readMinutes > 0) l10n.helpReadMinutes(article.readMinutes),
      l10n.helpUpdatedOn(DatesIst.date(article.updatedAt)),
    ];
    return Text(
      parts.join(' · '),
      style: context.type.caption.copyWith(color: context.colors.muted),
    );
  }
}
