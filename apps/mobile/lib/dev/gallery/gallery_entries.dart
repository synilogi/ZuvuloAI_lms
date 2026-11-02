import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/format/ist.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/theme.dart';
import '../../shared/domain/live_class.dart' show LiveAttendance;
import '../../shared/entitlements/entitlements.dart';
import '../../shared/widgets/navigation/app_nav_bar.dart';
import '../../shared/widgets/widgets.dart';

// Developer-only: sample copy below is illustrative text for reviewing components, never shown
// to users and never compiled into staging or prod (see main_dev.dart).

/// One gallery specimen. The same list drives the gallery screen and the component tests.
class GalleryEntry {
  const GalleryEntry(this.group, this.name, this.builder);

  final String group;
  final String name;
  final WidgetBuilder builder;
}

String _istDate(DateTime instant) {
  final t = Ist.wallClock(instant);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)} IST';
}

final List<GalleryEntry> galleryEntries = [
  // Actions
  GalleryEntry('Actions', 'AppButton variants', (_) => const _ButtonsDemo()),
  GalleryEntry(
    'Actions',
    'AppIconButton with badge',
    (_) => Row(
      children: [
        AppIconButton(icon: AppIcons.notifications, label: 'Notifications', onPressed: () {}),
        AppIconButton(
          icon: AppIcons.notifications,
          label: 'Notifications, 3 unread',
          badgeCount: 3,
          onPressed: () {},
        ),
        const AppIconButton(icon: AppIcons.search, label: 'Search (disabled)', onPressed: null),
      ],
    ),
  ),
  GalleryEntry(
    'Actions',
    'StickyActionBar',
    (_) => StickyActionBar(
      secondary: AppButton(
        label: 'Save draft',
        variant: AppButtonVariant.secondary,
        onPressed: () {},
      ),
      primary: AppButton(label: 'Submit', onPressed: () {}),
    ),
  ),
  GalleryEntry(
    'Actions',
    'AppFab',
    (_) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppFab(label: 'Schedule class', icon: AppIcons.add, onPressed: () {}),
    ),
  ),

  // Inputs
  GalleryEntry('Inputs', 'AppTextField states', (_) => const _TextFieldsDemo()),
  GalleryEntry(
    'Inputs',
    'AppSearchField',
    (_) => AppSearchField(hintText: 'Search students', onChanged: (_) {}),
  ),
  GalleryEntry(
    'Inputs',
    'SearchLauncher',
    (_) => SearchLauncher(hintText: 'Search courses', onTap: () {}),
  ),
  GalleryEntry('Inputs', 'AppSelectField', (_) => const _SelectDemo()),
  GalleryEntry(
    'Navigation',
    'CommonAppBar variants',
    (_) => Column(
      children: [
        SizedBox(
          height: Sizes.appBar,
          child: CommonAppBar(
            title: 'Assignments',
            onBack: () {},
            automaticallyImplyLeading: false,
          ),
        ),
        const SizedBox(height: Space.s3),
        const SizedBox(
          height: Sizes.appBarProfile,
          child: CommonAppBar(
            automaticallyImplyLeading: false,
            leadingWidth: Space.s4 + AvatarSizes.md + Space.s3,
            leading: Padding(
              padding: EdgeInsets.only(left: Space.s4, right: Space.s3),
              child: Center(child: AvatarInitials(name: 'Ananya Rao')),
            ),
            title: 'Good morning, Ananya',
            subtitle: 'Beginner · Rank I',
          ),
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Navigation',
    'AppBackdrop (page ground)',
    (_) => const SizedBox(height: 120, child: AppBackdrop(child: SizedBox.expand())),
  ),
  GalleryEntry(
    'Containers',
    'DetailHeader, MetaItem',
    (_) => const DetailHeader(
      icon: AppIcons.assignment,
      eyebrow: 'Class 10 Mathematics · Quadratic equations',
      badge: StatusBadge(StatusKind.overdue),
      title: 'Timing exercise',
      facts: [
        MetaItem(icon: AppIcons.date, label: 'Due 5 Oct 2026, 8:34 AM'),
        MetaItem(icon: AppIcons.check, label: 'Out of 100 points'),
      ],
    ),
  ),
  GalleryEntry(
    'Containers',
    'ItemCard',
    (_) => ItemCard(
      icon: AppIcons.assignment,
      tone: Tone.warn,
      eyebrow: 'Class 10 Mathematics',
      badge: const StatusBadge(StatusKind.overdue),
      title: 'Timing exercise',
      facts: const [MetaItem(icon: AppIcons.date, label: 'Due 4 days ago')],
      onTap: () {},
    ),
  ),
  GalleryEntry(
    'Containers',
    'FactStrip, InfoChips',
    (_) => const Column(
      children: [
        FactStrip(
          facts: [
            Fact(icon: AppIcons.level, value: 'Beginner', label: 'Level'),
            Fact(icon: AppIcons.lessonReading, value: '7', label: 'Lessons'),
            Fact(icon: AppIcons.duration, value: '2h 22m', label: 'Length', tone: Tone.info),
          ],
        ),
        SizedBox(height: Space.s3),
        InfoChips(items: [(AppIcons.format, 'Self-paced'), (AppIcons.language, 'en-IN')]),
      ],
    ),
  ),
  GalleryEntry(
    'Learning',
    'CoverBadge',
    (_) => const SizedBox(
      width: 220,
      child: Stack(
        children: [
          CourseCover(motif: CoverMotif.houses),
          Positioned(
            left: Space.s2,
            top: Space.s2,
            child: CoverBadge(label: 'Beginner'),
          ),
        ],
      ),
    ),
  ),
  GalleryEntry(
    'States',
    'ToneMark',
    (_) => const Wrap(
      spacing: Space.s3,
      children: [
        ToneMark(icon: AppIcons.success),
        ToneMark(icon: AppIcons.lock, tone: Tone.warn),
        ToneMark(icon: AppIcons.warning, tone: Tone.danger),
      ],
    ),
  ),
  GalleryEntry(
    'Containers',
    'IconTile tones',
    (_) => Wrap(
      spacing: Space.s3,
      children: [for (final tone in Tone.values) IconTile(icon: AppIcons.rank, tone: tone)],
    ),
  ),
  GalleryEntry('Inputs', 'Switch, checkbox and radio rows', (_) => const _TogglesDemo()),
  GalleryEntry(
    'Inputs',
    'AppDateTimeField (IST)',
    (_) => Column(
      children: [
        AppDateTimeField(
          label: 'Starts',
          value: DateTime.utc(2026, 9, 22, 18, 30),
          format: _istDate,
          onChanged: (_) {},
        ),
        const SizedBox(height: Space.s4),
        AppDateTimeField(
          label: 'Due date',
          value: null,
          format: _istDate,
          errorText: 'Choose a due date.',
          onChanged: (_) {},
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Inputs',
    'AppFilePickerTile states',
    (_) => Column(
      children: [
        AppFilePickerTile(
          name: 'birth-chart-worksheet.pdf',
          sizeLabel: '2.4 MB',
          kind: PickedFileKind.pdf,
          onRemove: () {},
        ),
        const SizedBox(height: Space.s2),
        AppFilePickerTile(
          name: 'chart-photo.jpg',
          sizeLabel: '1.1 MB',
          kind: PickedFileKind.image,
          progress: 0.42,
          onCancel: () {},
        ),
        const SizedBox(height: Space.s2),
        AppFilePickerTile(
          name: 'essay.pdf',
          sizeLabel: '3.0 MB',
          kind: PickedFileKind.pdf,
          failed: true,
          onRetry: () {},
          onRemove: () {},
        ),
      ],
    ),
  ),
  GalleryEntry('Inputs', 'FilterChipBar with counts', (_) => const _ChipsDemo()),
  GalleryEntry(
    'Inputs',
    'AppFilterChip (multi-choice)',
    (_) => Wrap(
      spacing: Space.s2,
      children: [
        AppFilterChip(label: 'Everything', selected: false, onTap: () {}),
        AppFilterChip(label: 'Live', count: 3, selected: true, onTap: () {}),
        AppFilterChip(label: 'Deadlines', count: 0, selected: false, onTap: () {}),
      ],
    ),
  ),
  GalleryEntry(
    'Inputs',
    'FieldRow of AppSelectField',
    (_) => FieldRow(
      children: [
        AppSelectField<String>(
          label: 'Sort by',
          value: 'active',
          onChanged: (_) {},
          options: const [SelectOption('active', 'Last active'), SelectOption('name', 'Name')],
        ),
        AppSelectField<String>(
          label: 'Course',
          value: '',
          onChanged: (_) {},
          options: const [SelectOption('', 'Every course')],
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Inputs',
    'FormErrorSummary',
    (_) => const FormErrorSummary(
      issues: [
        FormIssue(fieldLabel: 'Title', message: 'Enter a title.'),
        FormIssue(fieldLabel: 'Meeting link', message: 'Use an https:// link.'),
      ],
    ),
  ),

  // Containers
  GalleryEntry(
    'Containers',
    'QuickActionTile row',
    (_) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: QuickActionTile(label: 'Review queue', icon: AppIcons.review, onTap: () {}),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: QuickActionTile(label: 'Schedule a class', icon: AppIcons.live, onTap: () {}),
          ),
        ],
      ),
    ),
  ),
  GalleryEntry(
    'Containers',
    'TileGrid of KpiTile',
    (_) => const TileGrid(
      children: [
        KpiTile(label: 'Learners', value: '44', delta: 2.3, comparisonLabel: 'vs last period'),
        KpiTile(label: 'Courses', value: '6', delta: 0, comparisonLabel: 'vs last period'),
        KpiTile(label: 'Completion rate', value: '58%'),
      ],
    ),
  ),
  GalleryEntry(
    'Actions',
    'ActionPair (fits, then stacks)',
    (_) => Column(
      children: [
        ActionPair(
          primary: AppButton(label: 'Submit', onPressed: () {}),
          secondary: AppButton(
            label: 'Save draft',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
        const SizedBox(height: Space.s4),
        ActionPair(
          primary: AppButton(label: 'Return for changes', onPressed: () {}),
          secondary: AppButton(
            label: 'Save the draft for later',
            variant: AppButtonVariant.tertiary,
            onPressed: () {},
          ),
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Actions',
    'FabLayout with AppFab',
    (_) => SizedBox(
      height: 200,
      child: FabLayout(
        fab: AppFab(label: 'Schedule a class', icon: AppIcons.add, onPressed: () {}),
        body: const Center(child: Text('A list page')),
      ),
    ),
  ),
  GalleryEntry(
    'Containers',
    'AppCard + SectionHeader',
    (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Your courses', actionLabel: 'See all', onAction: () {}),
        AppCard(onTap: () {}, child: const Text('Class 10 Mathematics — Chapter 3 of 8')),
      ],
    ),
  ),
  GalleryEntry(
    'Containers',
    'GroupedList of AppListTile',
    (_) => GroupedList(
      title: 'Account',
      children: [
        AppListTile(
          title: 'Asha Verma',
          subtitle: 'Learner',
          leading: const AvatarInitials(name: 'Asha Verma'),
          showChevron: true,
          onTap: () {},
        ),
        AppListTile(
          title: 'Notifications',
          meta: '3 unread',
          leading: const AppIcon(AppIcons.notifications),
          trailing: const StatusBadge(StatusKind.important),
          onTap: () {},
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Containers',
    'KeyValueTable',
    (_) => const KeyValueTable(
      rows: [
        ('Plan', 'Professional (annual)'),
        ('Renews', '22 Sep 2027'),
        ('Learners', '284 of 500'),
      ],
    ),
  ),

  // Status
  GalleryEntry(
    'Status',
    'StatusBadge — every status',
    (_) => Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [for (final kind in StatusKind.values) StatusBadge(kind)],
    ),
  ),
  GalleryEntry(
    'Status',
    'StatusBadge md + label override',
    (_) => const Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        StatusBadge(StatusKind.published, size: StatusBadgeSize.md),
        StatusBadge(StatusKind.startingSoon, labelOverride: 'Starts in 12 min'),
        StatusBadge(StatusKind.live, size: StatusBadgeSize.md),
      ],
    ),
  ),
  GalleryEntry(
    'Status',
    'LiveAttendanceBadge — every record',
    (_) => Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [for (final record in LiveAttendance.values) LiveAttendanceBadge(record)],
    ),
  ),
  GalleryEntry(
    'Status',
    'ProgressRing and ProgressBar',
    (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.s4,
          children: [
            ProgressRing(value: 0),
            ProgressRing(value: 0.36),
            ProgressRing(value: 1, size: 72),
            ProgressRing(value: 0.6, size: 32, showLabel: false),
          ],
        ),
        SizedBox(height: Space.s4),
        ProgressBar(value: 0.64),
      ],
    ),
  ),
  GalleryEntry(
    'Status',
    'KpiTile',
    (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiTile(
          label: 'Active learners',
          value: '1,284',
          delta: 12.4,
          comparisonLabel: 'vs previous 90 days',
        ),
        SizedBox(height: Space.s3),
        KpiTile(
          label: 'Overdue reviews',
          value: '7',
          delta: 40,
          higherIsBetter: false,
          comparisonLabel: 'vs previous 30 days',
        ),
        SizedBox(height: Space.s3),
        KpiTile(label: 'Certificates issued', value: '96', delta: 0),
      ],
    ),
  ),
  GalleryEntry(
    'Status',
    'AvatarInitials',
    (_) => const Wrap(
      spacing: Space.s2,
      children: [
        AvatarInitials(name: 'Asha Verma'),
        AvatarInitials(name: 'Ravi'),
        AvatarInitials(name: 'Meera Krishnan Iyer', size: 56),
      ],
    ),
  ),

  // Charts
  GalleryEntry(
    'Charts',
    'Sparkline',
    (_) => const Sparkline(
      values: [3, 5, 4, 8, 7, 9, 12],
      semanticLabel: 'Enrolments rising from 3 to 12 over 7 weeks',
    ),
  ),
  GalleryEntry(
    'Charts',
    'TrendChart',
    (_) => const TrendChart(title: 'Enrolments', points: _series),
  ),
  GalleryEntry(
    'Charts',
    'ColumnChart',
    (_) => const ColumnChart(title: 'Completions', points: _series),
  ),
  GalleryEntry(
    'Charts',
    'BarList',
    (_) => const BarList(
      title: 'Top courses',
      points: [
        ChartPoint('Class 10 Mathematics', 184, '184 learners'),
        ChartPoint('RAS Prelims Foundation', 122, '122 learners'),
        ChartPoint('Reading the houses', 64, '64 learners'),
      ],
    ),
  ),

  // Overlays
  GalleryEntry('Overlays', 'AppDialog (inline)', (_) => const _InlineDialog()),
  GalleryEntry(
    'Overlays',
    'Dialogs, sheets, snackbars (launchers)',
    (_) => const _OverlayLaunchers(),
  ),

  // States
  GalleryEntry(
    'States',
    'SkeletonBox, DelayedLoading and AppDivider',
    (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(width: 180, height: 18),
        SizedBox(height: Space.s3),
        AppDivider(),
        SizedBox(height: Space.s3),
        DelayedLoading(skeleton: SkeletonList(count: 2)),
      ],
    ),
  ),
  GalleryEntry('States', 'ConstellationArt', (_) => const Center(child: ConstellationArt())),
  GalleryEntry(
    'Brand',
    'BrandLogo and BrandMark',
    (_) => const Column(
      children: [
        BrandLogo(),
        SizedBox(height: Space.s4),
        BrandMark(),
      ],
    ),
  ),
  GalleryEntry(
    'States',
    'Skeletons',
    (_) => const Column(children: [SkeletonCard(), SkeletonList(count: 3)]),
  ),
  GalleryEntry(
    'States',
    'SkeletonDetail and SkeletonDashboard',
    (_) => const Column(
      children: [
        SizedBox(height: 420, child: SkeletonDetail(showMedia: true)),
        SizedBox(height: 520, child: SkeletonDashboard()),
      ],
    ),
  ),
  GalleryEntry(
    'States',
    'EmptyState',
    (_) => SizedBox(
      height: 360,
      child: EmptyState(
        title: 'No courses yet',
        message: 'Explore the catalogue to start learning.',
        actionLabel: 'Explore',
        onAction: () {},
      ),
    ),
  ),
  GalleryEntry(
    'States',
    'EmptyState.noMatches',
    (_) => SizedBox(height: 280, child: EmptyState.noMatches(onClearFilters: () {})),
  ),
  GalleryEntry(
    'States',
    'ErrorState',
    (_) => SizedBox(
      height: 360,
      child: ErrorState(onRetry: () {}, detail: 'The server did not respond.'),
    ),
  ),
  GalleryEntry(
    'States',
    'ErrorBoundary (crashed route)',
    (_) => SizedBox(height: 320, child: ErrorBoundary(onGoHome: () {})),
  ),
  GalleryEntry('States', 'OfflineBanner', (_) => const OfflineBanner()),
  GalleryEntry('States', 'AsyncView (loaded and refused)', (_) => const _AsyncViewDemo()),
  GalleryEntry(
    'States',
    'PermissionDeniedView',
    (_) => const SizedBox(height: 320, child: PermissionDeniedView()),
  ),
  GalleryEntry(
    'States',
    'FeatureUnavailableView (member / admin)',
    (_) => Column(
      children: [
        const SizedBox(height: 320, child: FeatureUnavailableView()),
        SizedBox(height: 360, child: FeatureUnavailableView(onReviewPlan: () {})),
      ],
    ),
  ),
  GalleryEntry(
    'States',
    'SubscriptionStateView',
    (_) => Column(
      children: [
        SizedBox(
          height: 360,
          child: SubscriptionStateView(problem: SubscriptionProblem.expired, onReviewPlan: () {}),
        ),
        const SizedBox(
          height: 320,
          child: SubscriptionStateView(problem: SubscriptionProblem.required),
        ),
      ],
    ),
  ),
  GalleryEntry(
    'States',
    'NotFoundView',
    (_) => SizedBox(height: 340, child: NotFoundView(onBack: () {})),
  ),
  GalleryEntry(
    'States',
    'UnavailableLessonView',
    (_) => SizedBox(
      height: 360,
      child: UnavailableLessonView(
        lockedReason: 'Pass the Chapter 1 quiz to unlock this chapter.',
        onOpenCurriculum: () {},
      ),
    ),
  ),

  // Learning
  GalleryEntry(
    'Learning',
    'CourseCover motifs',
    (_) => GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.s2,
      crossAxisSpacing: Space.s2,
      childAspectRatio: 16 / 10,
      children: [
        for (final motif in CoverMotif.values.where((m) => m != CoverMotif.unknown))
          CourseCover(motif: motif, semanticLabel: motif.name),
      ],
    ),
  ),
  GalleryEntry(
    'Learning',
    'LessonTypeIcon',
    (_) =>
        Wrap(spacing: Space.s3, children: [for (final t in LessonType.values) LessonTypeIcon(t)]),
  ),
  GalleryEntry('Learning', 'CurriculumTree', (_) => const _CurriculumDemo()),
  GalleryEntry('Learning', 'ArticleBody', (_) => const _ArticleDemo()),
  GalleryEntry(
    'Learning',
    'LessonNavBar states',
    (_) => Column(
      children: [
        LessonNavBar(
          completion: const CanComplete(),
          onPrevious: () {},
          onNext: () {},
          onMarkComplete: () {},
        ),
        const SizedBox(height: Space.s2),
        LessonNavBar(completion: const CompletionHint('Watch 80% to complete'), onNext: () {}),
        const SizedBox(height: Space.s2),
        LessonNavBar(completion: const AlreadyComplete(), onPrevious: () {}, onNext: () {}),
      ],
    ),
  ),
  GalleryEntry('Learning', 'QuizQuestionCard', (_) => const _QuizDemo()),
  GalleryEntry('Learning', 'RubricScorer', (_) => const _RubricDemo()),
  GalleryEntry(
    'Learning',
    'CertificateCanvas',
    (_) => const CertificateCanvas(
      semanticLabel: 'Certificate of completion: Asha Verma, Class 10 Mathematics',
      data: CertificateCanvasData(
        academyName: 'ZuviloAI Academy',
        heading: 'Certificate of completion',
        statement: 'has successfully completed',
        learnerName: 'Asha Verma',
        courseTitle: 'Class 10 Mathematics',
        credentialId: 'SYN-7F3K-2Q9D',
        accent: CertificateAccent.indigo,
        details: ['Score 92%', '24 hours'],
        issuedOnLabel: '22 Sep 2026',
        signatories: [CertificateSignatory(name: 'Dr. Meera Iyer', title: 'Lead instructor')],
      ),
    ),
  ),
  GalleryEntry(
    'Learning',
    'RankRing + StudyWeekBars',
    (_) => const Column(
      children: [
        RankRing(rankName: 'Rank III · Advanced', progressToNext: 0.62),
        RankRing(rankName: 'Rank I · Beginner', progressToNext: null),
        SizedBox(height: Space.s5),
        StudyWeekBars(
          days: [
            StudyDay(label: 'Mon', minutes: 20),
            StudyDay(label: 'Tue', minutes: 45),
            StudyDay(label: 'Wed', minutes: 0),
            StudyDay(label: 'Thu', minutes: 30),
            StudyDay(label: 'Fri', minutes: 60, isToday: true),
            StudyDay(label: 'Sat', minutes: 0),
            StudyDay(label: 'Sun', minutes: 0),
          ],
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Learning',
    'CountdownChip',
    (_) => const Wrap(
      spacing: Space.s2,
      children: [
        CountdownChip(label: 'Starts in 12 min', tone: Tone.info),
        CountdownChip(label: 'Due today'),
        CountdownChip(label: 'Overdue by 2 days', tone: Tone.danger),
      ],
    ),
  ),
  GalleryEntry('Navigation', 'AppNavBar', (_) => const _NavBarDemo()),
  GalleryEntry(
    'Containers',
    'AuroraBackdrop',
    (context) => SizedBox(
      height: 220,
      child: AuroraBackdrop(
        child: Center(child: Text('Welcome back', style: context.type.displayM)),
      ),
    ),
  ),
  GalleryEntry(
    'Containers',
    'HueTile',
    (_) => Wrap(
      spacing: Space.s3,
      children: [for (final hue in Hue.values) HueTile(icon: AppIcons.learning, hue: hue)],
    ),
  ),
  GalleryEntry(
    'Containers',
    'StripCard',
    (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StripCard(
          strip: context.colors.hue(Hue.pink),
          stripIcon: AppIcons.live,
          stripLabel: 'RAS Prelims Foundation Batch',
          badge: const StatusBadge(StatusKind.scheduled),
          title: 'Rajasthan geography: live revision',
          facts: const [
            MetaItem(icon: AppIcons.date, label: '24 Oct 2026, 6:00 PM · 1h'),
            MetaItem(icon: AppIcons.people, label: '18 of 40 seats'),
          ],
          onTap: () {},
        ),
        const SizedBox(height: Space.s3),
        StripCard(
          strip: context.colors.tone(Tone.danger),
          stripIcon: AppIcons.assignment,
          stripLabel: 'Class 10 Maths',
          badge: const StatusBadge(StatusKind.overdue),
          title: 'Quadratic equations worksheet',
          subtitle: 'Ananya Rao handed this in 2 days late.',
          footer: AppButton(label: 'Review', onPressed: () {}),
          onTap: () {},
        ),
      ],
    ),
  ),
  GalleryEntry(
    'Status',
    'StatSummaryCard',
    (_) => StatSummaryCard(
      figures: [
        StatFigure(
          value: '4',
          label: 'Waiting for review',
          icon: AppIcons.review,
          hue: Hue.orange,
          onTap: () {},
        ),
        const StatFigure(
          value: '2',
          label: 'Live classes ahead',
          icon: AppIcons.live,
          hue: Hue.pink,
        ),
        StatFigure(
          value: '128',
          label: 'Learners',
          icon: AppIcons.people,
          hue: Hue.green,
          onTap: () {},
        ),
      ],
    ),
  ),
  GalleryEntry('Inputs', 'ListToolbar and FiltersButton', (_) => const _ListToolbarDemo()),
  GalleryEntry('Inputs', 'PagerRow', (_) => PagerRow(page: 2, pages: 5, onPage: (_) {})),
  GalleryEntry(
    'Learning',
    'PracticeThumb',
    (context) => Wrap(
      spacing: Space.s3,
      children: [
        PracticeThumb(icon: AppIcons.quiz, colors: context.colors.hue(Hue.pink)),
        PracticeThumb(icon: AppIcons.assignment, colors: context.colors.hue(Hue.orange)),
        PracticeThumb(icon: AppIcons.assignment, colors: context.colors.tone(Tone.danger)),
      ],
    ),
  ),
  GalleryEntry(
    'Learning',
    'CardActionBar',
    (context) => Column(
      children: [
        const CardActionBar(label: 'Start the quiz'),
        const SizedBox(height: Space.s3),
        CardActionBar(label: 'Open assignment', colors: context.colors.hue(Hue.orange)),
      ],
    ),
  ),
  GalleryEntry(
    'Learning',
    'CardNote',
    (_) => const CardNote(
      text: 'Finish the other lessons in “Chapter 1” to take this quiz.',
      icon: AppIcons.lock,
    ),
  ),
];

const _series = [
  ChartPoint('Jun', 12, '12'),
  ChartPoint('Jul', 18, '18'),
  ChartPoint('Aug', 15, '15'),
  ChartPoint('Sep', 26, '26'),
  ChartPoint('Oct', 22, '22'),
  ChartPoint('Nov', 31, '31'),
];

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        AppButton(label: 'Primary', onPressed: () {}),
        AppButton(label: 'Secondary', variant: AppButtonVariant.secondary, onPressed: () {}),
        AppButton(label: 'Tertiary', variant: AppButtonVariant.tertiary, onPressed: () {}),
        AppButton(label: 'Revoke', variant: AppButtonVariant.destructive, onPressed: () {}),
        AppButton(
          label: 'Sign out',
          variant: AppButtonVariant.destructiveOutline,
          onPressed: () {},
        ),
        AppButton(label: 'With icon', icon: AppIcons.add, onPressed: () {}),
        AppButton(label: 'Saving', busy: true, onPressed: () {}),
        const AppButton(label: 'Disabled', onPressed: null),
        AppButton(
          label: 'Large, full width',
          size: AppButtonSize.lg,
          expand: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _TextFieldsDemo extends StatelessWidget {
  const _TextFieldsDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTextField(
          label: 'Email',
          hintText: 'name@example.com',
          prefixIcon: AppIcons.email,
          required: true,
        ),
        SizedBox(height: Space.s4),
        AppTextField(
          label: 'Password',
          hintText: 'Enter your password',
          prefixIcon: AppIcons.lock,
          obscure: true,
          helperText: 'At least 8 characters.',
        ),
        SizedBox(height: Space.s4),
        AppTextField(label: 'Title', initialValue: 'Hi', errorText: 'Enter at least 3 characters.'),
        SizedBox(height: Space.s4),
        AppTextField(label: 'Feedback', maxLength: 500, minLines: 3, maxLines: 6),
        SizedBox(height: Space.s4),
        AppTextField(label: 'Credential ID', initialValue: 'SYN-7F3K', enabled: false),
      ],
    );
  }
}

class _SelectDemo extends StatefulWidget {
  const _SelectDemo();

  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  String? _level = 'beginner';

  @override
  Widget build(BuildContext context) {
    return AppSelectField<String>(
      label: 'Level',
      value: _level,
      onChanged: (v) => setState(() => _level = v),
      options: const [
        SelectOption('beginner', 'Beginner'),
        SelectOption('intermediate', 'Intermediate'),
        SelectOption(
          'advanced',
          'Advanced',
          description: 'For students preparing for board or competitive exams',
        ),
      ],
    );
  }
}

class _TogglesDemo extends StatefulWidget {
  const _TogglesDemo();

  @override
  State<_TogglesDemo> createState() => _TogglesDemoState();
}

class _TogglesDemoState extends State<_TogglesDemo> {
  bool _email = true;
  bool _agree = false;
  String _cycle = 'monthly';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSwitchRow(
          title: 'Email',
          subtitle: 'A copy of each notification',
          value: _email,
          onChanged: (v) => setState(() => _email = v),
        ),
        const AppSwitchRow(
          title: 'In-app',
          value: true,
          onChanged: null,
          lockedReason: 'Account and system notices are always on.',
        ),
        AppCheckboxRow(
          title: 'Notify learners',
          value: _agree,
          onChanged: (v) => setState(() => _agree = v),
        ),
        AppRadioGroup<String>(
          label: 'Billing cycle',
          value: _cycle,
          onChanged: (v) => setState(() => _cycle = v),
          options: const [
            RadioOption('monthly', 'Monthly'),
            RadioOption('annual', 'Annual', description: 'Two months free'),
          ],
        ),
      ],
    );
  }
}

class _ChipsDemo extends StatefulWidget {
  const _ChipsDemo();

  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

class _ChipsDemoState extends State<_ChipsDemo> {
  String _tab = 'review';

  @override
  Widget build(BuildContext context) {
    return FilterChipBar<String>(
      padding: EdgeInsets.zero,
      selected: _tab,
      onSelected: (v) => setState(() => _tab = v),
      options: const [
        FilterOption('review', 'To review', count: 12),
        FilterOption('overdue', 'Overdue', count: 3),
        FilterOption('graded', 'Graded', count: 48),
        FilterOption('returned', 'Returned', count: 2),
      ],
    );
  }
}

class _InlineDialog extends StatelessWidget {
  const _InlineDialog();

  @override
  Widget build(BuildContext context) {
    return const AppDialog(
      title: 'Revoke certificate?',
      confirmLabel: 'Revoke',
      destructive: true,
      consequences: [
        'The verification page will show this certificate as revoked.',
        'The learner is notified.',
      ],
    );
  }
}

class _OverlayLaunchers extends StatelessWidget {
  const _OverlayLaunchers();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        AppButton(
          label: 'Confirm dialog',
          variant: AppButtonVariant.secondary,
          onPressed: () => showConfirmDialog(
            context,
            title: 'Publish course?',
            confirmLabel: 'Publish',
            consequences: const ['Learners can find and enrol in it.'],
          ),
        ),
        AppButton(
          label: 'Dialog with error',
          variant: AppButtonVariant.secondary,
          onPressed: () => showConfirmDialog(
            context,
            title: 'Archive course?',
            confirmLabel: 'Archive',
            destructive: true,
            onConfirm: () async => 'The course has live classes scheduled.',
          ),
        ),
        AppButton(
          label: 'Filter sheet',
          variant: AppButtonVariant.secondary,
          onPressed: () => showAppBottomSheet<void>(
            context,
            builder: (sheet) => FilterSheet(
              title: 'Filter students',
              onApply: () => Navigator.of(sheet).pop(),
              onReset: () {},
              children: const [AppTextField(label: 'Course')],
            ),
          ),
        ),
        AppButton(
          label: 'Snackbar with undo',
          variant: AppButtonVariant.secondary,
          onPressed: () => showAppSnackbar(
            context,
            'Notification removed',
            tone: SnackTone.success,
            onUndo: () {},
          ),
        ),
      ],
    );
  }
}

class _CurriculumDemo extends StatelessWidget {
  const _CurriculumDemo();

  @override
  Widget build(BuildContext context) {
    return CurriculumTree(
      onLessonTap: (_) {},
      chapters: const [
        CurriculumChapterNode(
          id: 'c1',
          title: 'Chapter 1 · The sky we read',
          lessons: [
            CurriculumLessonNode(
              id: 'l1',
              title: 'Welcome',
              type: LessonType.video,
              state: LessonNodeState.completed,
              numberLabel: '1.1',
              durationLabel: '6 min',
            ),
            CurriculumLessonNode(
              id: 'l2',
              title: 'The twelve signs',
              type: LessonType.reading,
              state: LessonNodeState.inProgress,
              numberLabel: '1.2',
              durationLabel: '12 min',
              isCurrent: true,
            ),
            CurriculumLessonNode(
              id: 'l3',
              title: 'Chapter quiz',
              type: LessonType.assessment,
              state: LessonNodeState.available,
              numberLabel: '1.3',
            ),
          ],
        ),
        CurriculumChapterNode(
          id: 'c2',
          title: 'Chapter 2 · Houses',
          lessons: [
            CurriculumLessonNode(
              id: 'l4',
              title: 'The first house',
              type: LessonType.document,
              state: LessonNodeState.locked,
              numberLabel: '2.1',
              lockedReason: 'Pass the Chapter 1 quiz to unlock this chapter.',
            ),
          ],
        ),
      ],
    );
  }
}

class _QuizDemo extends StatefulWidget {
  const _QuizDemo();

  @override
  State<_QuizDemo> createState() => _QuizDemoState();
}

class _QuizDemoState extends State<_QuizDemo> {
  Set<String> _single = {};
  Set<String> _multi = {'a'};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuizQuestionCard(
          number: 4,
          total: 10,
          prompt: 'What is the value of the discriminant of x² − 5x + 6 = 0?',
          kind: QuestionKind.single,
          options: const [
            QuestionOption('a', '1'),
            QuestionOption('b', '25'),
            QuestionOption('c', '−1'),
          ],
          selectedIds: _single,
          onSelectionChanged: (v) => setState(() => _single = v),
        ),
        const SizedBox(height: Space.s5),
        QuizQuestionCard(
          number: 5,
          total: 10,
          prompt: 'Which of these are prime numbers?',
          kind: QuestionKind.multiple,
          options: const [
            QuestionOption('a', '7'),
            QuestionOption('b', '9'),
            QuestionOption('c', '13'),
          ],
          selectedIds: _multi,
          onSelectionChanged: (v) => setState(() => _multi = v),
        ),
        const SizedBox(height: Space.s5),
        QuizQuestionCard(
          number: 6,
          total: 10,
          prompt: 'Every rational number is a real number.',
          kind: QuestionKind.trueFalse,
          onSelectionChanged: (_) {},
        ),
        const SizedBox(height: Space.s5),
        QuizQuestionCard(
          number: 7,
          total: 10,
          prompt: 'Name the capital of Rajasthan.',
          kind: QuestionKind.shortAnswer,
          onTextChanged: (_) {},
        ),
      ],
    );
  }
}

class _RubricDemo extends StatefulWidget {
  const _RubricDemo();

  @override
  State<_RubricDemo> createState() => _RubricDemoState();
}

class _RubricDemoState extends State<_RubricDemo> {
  final Map<String, num> _scores = {'accuracy': 8, 'reasoning': 5};

  @override
  Widget build(BuildContext context) {
    return RubricScorer(
      scores: _scores,
      onChanged: (id, v) => setState(() => _scores[id] = v),
      criteria: const [
        ScoringCriterion(id: 'accuracy', title: 'Chart accuracy', maxPoints: 10),
        ScoringCriterion(
          id: 'reasoning',
          title: 'Interpretation',
          description: 'Cites placements and aspects',
          maxPoints: 10,
        ),
      ],
    );
  }
}

/// The tiny article dialect a help article and a reading lesson are written in.
class _ArticleDemo extends StatelessWidget {
  const _ArticleDemo();

  static const _body = '''
## Solving a quadratic equation

A quadratic equation has **at most two roots**. Find what kind of roots to expect before you
look for them.

> The discriminant tells you the answer's shape before you find it.

- Write the equation as ax² + bx + c = 0
- Work out b² − 4ac
- Then choose a method

1. Try to factorise
2. Otherwise use the formula
3. Check each root in the equation

More in the _NCERT textbook_ and at [Wikipedia](https://example.org/quadratic-equation).''';

  @override
  Widget build(BuildContext context) => const ArticleBody(body: _body);
}

/// One value with its two other states: what the screen shows, and what a refusal shows.
class _AsyncViewDemo extends StatelessWidget {
  const _AsyncViewDemo();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AsyncView<String>(
        value: const AsyncValue.data('The value this screen reads'),
        onRetry: () {},
        data: (value) => Text(value, style: context.type.bodyM),
      ),
      const SizedBox(height: Space.s4),
      SizedBox(
        height: 260,
        child: AsyncView<String>(
          value: const AsyncValue.error(ApiException(NotFoundFailure()), StackTrace.empty),
          onRetry: () {},
          data: (value) => Text(value),
        ),
      ),
    ],
  );
}

class _NavBarDemo extends StatefulWidget {
  const _NavBarDemo();

  @override
  State<_NavBarDemo> createState() => _NavBarDemoState();
}

class _NavBarDemoState extends State<_NavBarDemo> {
  var _index = 0;

  @override
  Widget build(BuildContext context) => AppNavBar(
    selectedIndex: _index,
    onDestinationSelected: (i) => setState(() => _index = i),
    destinations: const [
      AppNavDestination(icon: AppIcons.home, label: 'Home'),
      AppNavDestination(icon: AppIcons.learning, label: 'Courses'),
      AppNavDestination(icon: AppIcons.live, label: 'Live', access: ModuleAccess.locked),
      AppNavDestination(icon: AppIcons.quiz, label: 'Tests'),
      AppNavDestination(icon: AppIcons.profile, label: 'Profile'),
    ],
  );
}

class _ListToolbarDemo extends StatefulWidget {
  const _ListToolbarDemo();

  @override
  State<_ListToolbarDemo> createState() => _ListToolbarDemoState();
}

class _ListToolbarDemoState extends State<_ListToolbarDemo> {
  var _status = 'all';
  var _sort = 'updated';

  @override
  Widget build(BuildContext context) => ListToolbar(
    search: AppSearchField(hintText: 'Search courses', onChanged: (_) {}),
    activeFilters: _sort == 'updated' ? 0 : 1,
    onClearFilters: _sort == 'updated' ? null : () => setState(() => _sort = 'updated'),
    filters: (_) => AppSelectField<String>(
      label: 'Sort by',
      value: _sort,
      onChanged: (value) => setState(() => _sort = value),
      options: const [SelectOption('updated', 'Recently updated'), SelectOption('title', 'Title')],
    ),
    chips: FilterChipBar<String>(
      padding: EdgeInsets.zero,
      selected: _status,
      onSelected: (value) => setState(() => _status = value),
      options: const [
        FilterOption('all', 'All', count: 12),
        FilterOption('draft', 'Draft', count: 3),
        FilterOption('published', 'Published', count: 9),
      ],
    ),
  );
}
