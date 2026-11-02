import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/web_path_mapper.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/level.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../../../shared/session/current_user.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../live/live.dart';
import '../../../public_catalog/public_catalog.dart'
    show Course, allCoursesProvider, catalogLevelsProvider;
import '../../application/learner_home_providers.dart';
import '../widgets/home_cards.dart';
import '../widgets/learner_widgets.dart';

/// `/home` — the learner's starting point: pick up the lesson, the shortcuts, the courses they
/// hold and the catalogue's others, then the next class, what is due, what was opened lately and
/// the week, and last the way into Explore. Every section is the server's data and is left out
/// when there is none. It sits inside the learner shell, which draws the scaffold and the app bar
/// (with the greeting), so this is a body.
class LearnerHomeScreen extends ConsumerWidget {
  const LearnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(learnerHomeProvider);
    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(liveScheduleProvider);
        return ref.refresh(learnerHomeProvider.future);
      },
      child: AsyncView<LearnerHome>(
        value: home,
        onRetry: () => ref.invalidate(learnerHomeProvider),
        skeleton: const DelayedLoading(skeleton: SkeletonDashboard()),
        data: (value) => _Home(home: value),
      ),
    );
  }
}

/// At most this many rows in Home's "To do" and "Recently viewed": the rest is a tap away.
const _homeListLimit = 3;

class _Home extends ConsumerWidget {
  const _Home({required this.home});

  final LearnerHome home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final router = GoRouter.of(context);
    final role = ref.watch(currentUserProvider)?.role ?? UserRole.student;

    if (home.isEmpty) {
      return EmptyState(
        title: l10n.homeEmptyTitle,
        message: l10n.homeEmptyBody,
        actionLabel: l10n.actionExplore,
        onAction: () => router.go(AppRoutes.explore),
      );
    }

    VoidCallback? openUpcoming(UpcomingItem item) => switch (WebPathMapper.map(item.to, role)) {
      final target? => () => router.go(target),
      null => null,
    };

    // The server has already sorted: unfinished first, then most recently worked on.
    final continueWith = home.courses
        .where((course) => course.next != null && showsInProgress(course))
        .firstOrNull;
    // Live classes have their own section, read from the schedule (it carries the Join button);
    // the rest is the learner's coursework, soonest first as the server sent it.
    final toDo = home.upcoming.where((item) => item.kind != UpcomingKind.live).toList();
    final liveFallback = home.upcoming.where((item) => item.kind == UpcomingKind.live).firstOrNull;
    // The one course already in "Continue learning" is not repeated on its own.
    final showCourses =
        home.courses.isNotEmpty && (continueWith == null || home.courses.length > 1);
    final weekMinutes = home.week.fold<int>(0, (sum, d) => sum + d.minutes);
    final size = WindowSize.of(context);
    final gutter = size.gutter;
    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: child,
    );

    // The greeting is the shell's app bar. The page opens on where to pick up, on a tinted band
    // with the shortcuts beneath it; then the learner's courses and the catalogue's others, the
    // next class and what is due, what was opened lately, the week, and the way into Explore.
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.s6),
      children: [
        _Band(
          hue: Hue.violet,
          padding: const EdgeInsets.only(top: Space.s3, bottom: Space.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (continueWith != null) ...[
                padded(
                  ContinueCard(
                    course: continueWith,
                    onResume: () => router.go(
                      AppRoutes.learnLesson(continueWith.course.id, continueWith.next!.id),
                    ),
                  ),
                ),
                const SizedBox(height: Space.s4),
              ],
              padded(const _Shortcuts()),
            ],
          ),
        ),
        const SizedBox(height: Space.s4),
        if (showCourses) ...[
          padded(
            SectionHeader(
              title: l10n.homeYourCoursesTitle,
              icon: AppIcons.learning,
              iconColor: c.hue(Hue.violet).solid,
              actionLabel: l10n.actionSeeAll,
              onAction: () =>
                  router.go(AppRoutes.atHome(AppRoutes.myLearning(MyLearningTab.inProgress))),
            ),
          ),
          if (size.isCompact)
            _Carousel(
              gutter: gutter,
              children: [
                for (final course in home.courses)
                  LearnerCourseCard(
                    course: course,
                    onTap: () => router.go(AppRoutes.learnCourse(course.course.id)),
                  ),
              ],
            )
          else
            padded(
              _CourseGrid(
                courses: home.courses,
                columns: 2,
                onOpen: (course) => router.go(AppRoutes.learnCourse(course.course.id)),
              ),
            ),
          const SizedBox(height: Space.sectionGap - Space.s2),
        ],
        _DiscoverBand(home: home, gutter: gutter),
        _NextLiveClass(
          gutter: gutter,
          fallback: liveFallback,
          onOpenFallback: liveFallback == null ? null : openUpcoming(liveFallback),
        ),
        if (toDo.isNotEmpty) ...[
          padded(
            SectionHeader(
              title: l10n.homeToDoTitle,
              icon: AppIcons.assignment,
              iconColor: c.hue(Hue.orange).solid,
              actionLabel: toDo.length > _homeListLimit ? l10n.actionSeeAll : null,
              onAction: () => router.go(
                toDo.first.kind == UpcomingKind.assignment
                    ? AppRoutes.homeAssignments
                    : AppRoutes.homeAssessments,
              ),
            ),
          ),
          _Carousel(
            gutter: gutter,
            children: [
              for (final item in toDo.take(_homeListLimit))
                TodoCard(item: item, onTap: openUpcoming(item)),
            ],
          ),
          const SizedBox(height: Space.sectionGap - Space.s2),
        ],
        if (home.recent.isNotEmpty) ...[
          padded(
            SectionHeader(
              title: l10n.homeRecentTitle,
              icon: AppIcons.lessonVideo,
              iconColor: c.hue(Hue.blue).solid,
            ),
          ),
          _Carousel(
            gutter: gutter,
            children: [
              for (final lesson in home.recent)
                RecentLessonCard(
                  lesson: lesson,
                  onTap: () => router.go(AppRoutes.learnLesson(lesson.courseId, lesson.lessonId)),
                ),
            ],
          ),
          const SizedBox(height: Space.sectionGap - Space.s2),
        ],
        if (home.week.isNotEmpty) ...[
          padded(
            SectionHeader(
              title: l10n.homeThisWeekTitle,
              icon: AppIcons.trendUp,
              iconColor: c.hue(Hue.green).solid,
            ),
          ),
          padded(
            AppCard(
              color: c.hue(Hue.green).soft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: Sizes.iconTile,
                        height: Sizes.iconTile,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(
                          AppIcons.time,
                          size: IconSizes.md,
                          color: c.hue(Hue.green).solid,
                        ),
                      ),
                      const SizedBox(width: Space.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDurations.minutes(l10n, weekMinutes),
                              style: context.type.numeral.copyWith(
                                fontSize: context.type.titleL.fontSize,
                                color: c.hue(Hue.green).ink,
                              ),
                            ),
                            Text(
                              l10n.homeStudiedThisWeek,
                              style: context.type.caption.copyWith(color: c.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s4),
                  StudyWeekBars(days: studyWeek(home.week)),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.sectionGap),
        ],
        // The way into the whole catalogue closes the page.
        padded(_ExploreFooter(saved: home.saved.length)),
      ],
    );
  }
}

/// A full-width band that fades from a hue's soft tint into the page — it groups a stretch of
/// Home (the hero, the catalogue) the way a coloured section does on a store's front page.
class _Band extends StatelessWidget {
  const _Band({required this.hue, required this.child, this.padding = EdgeInsets.zero});

  final Hue hue;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final soft = context.colors.hue(hue).soft;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [soft, soft.withValues(alpha: 0)],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The learner's own places that the bar does not reach directly: their courses, assignments,
/// certificates and the rank ladder. Four across, or two at large text sizes.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final tiles = [
      HomeShortcut(
        label: l10n.navMyCourses,
        image: HomeArt.courses,
        hue: Hue.violet,
        onTap: () => router.go(AppRoutes.atHome(AppRoutes.myLearning(MyLearningTab.inProgress))),
      ),
      HomeShortcut(
        label: l10n.navAssignments,
        image: HomeArt.assignments,
        hue: Hue.orange,
        onTap: () => router.go(AppRoutes.homeAssignments),
      ),
      HomeShortcut(
        label: l10n.navCertificates,
        image: HomeArt.certificates,
        hue: Hue.gold,
        onTap: () => router.go(AppRoutes.homeCertificates),
      ),
      HomeShortcut(
        label: l10n.navRanks,
        image: HomeArt.ranks,
        hue: Hue.green,
        onTap: () => router.go(AppRoutes.homeRanks),
      ),
    ];
    final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 2 : 4;
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final tile in tiles.skip(i).take(columns)) Expanded(child: tile)],
          ),
      ],
    );
  }
}

/// The catalogue's other courses on a warm band: what the academy lists that the learner does not
/// hold yet. The catalogue is read on its own; while it loads, if it cannot be read, or when the
/// learner already holds everything, the band is left out — [_ExploreFooter] is still the way in.
class _DiscoverBand extends ConsumerWidget {
  const _DiscoverBand({required this.home, required this.gutter});

  /// How many catalogue courses the band shows before "See all".
  static const _limit = 6;

  final LearnerHome home;
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final router = GoRouter.of(context);
    final held = {for (final course in home.courses) course.course.id};
    final levelName = {
      for (final level in ref.watch(catalogLevelsProvider).value ?? const <Level>[])
        level.id: level.name,
    };
    final courses = [
      for (final course in ref.watch(allCoursesProvider).value ?? const <Course>[])
        if (!held.contains(course.id)) course,
    ].take(_limit).toList();
    if (courses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sectionGap - Space.s2),
      child: _Band(
        hue: Hue.gold,
        padding: const EdgeInsets.only(top: Space.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: SectionHeader(
                title: l10n.homeDiscoverTitle,
                icon: AppIcons.explore,
                iconColor: c.hue(Hue.gold).ink,
                actionLabel: l10n.actionSeeAll,
                onAction: () => router.go(AppRoutes.explore),
              ),
            ),
            _Carousel(
              gutter: gutter,
              children: [
                for (final course in courses)
                  DiscoverCourseCard(
                    course: course,
                    levelName: levelName[course.levelId] ?? '',
                    onTap: () => router.go(AppRoutes.learnCourse(course.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The foot of Home: the learner's saved courses, when there are any, and the way into Explore.
class _ExploreFooter extends StatelessWidget {
  const _ExploreFooter({required this.saved});

  /// How many courses the learner has saved.
  final int saved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (saved > 0) ...[
          GroupedList(
            children: [
              AppListTile(
                title: l10n.myLearningSaved,
                subtitle: l10n.catalogCourseCount(saved),
                leading: const IconTile(icon: AppIcons.bookmark, tone: Tone.warn),
                showChevron: true,
                onTap: () => router.go(AppRoutes.atHome(AppRoutes.myLearning(MyLearningTab.saved))),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
        ],
        AppButton(
          label: l10n.actionExplore,
          icon: AppIcons.explore,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => router.go(AppRoutes.explore),
        ),
      ],
    );
  }
}

/// The class that is live now, or the next one to start, with the way in (Join) or the way to a
/// seat (Register) exactly as the Live tab offers them. The schedule is read on its own: while it
/// loads, or if it cannot be read, the home feed's own entry for the class stands in, and with
/// neither the section is left out.
class _NextLiveClass extends ConsumerWidget {
  const _NextLiveClass({
    required this.gutter,
    required this.fallback,
    required this.onOpenFallback,
  });

  final double gutter;
  final UpcomingItem? fallback;
  final VoidCallback? onOpenFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final schedule = ref.watch(liveScheduleProvider).value;
    final now = ref.watch(liveClockProvider).value ?? DateTime.now().toUtc();
    final seats = ref.watch(liveRegistrationProvider);

    // The card offers the Live tab's own Register and Join, so it says their refusals the same way:
    // a class the host has not started, a full class, a room this phone could not open.
    listenForRegistrationFailures(context, ref);
    listenForJoinFailures(context, ref);

    final row = schedule == null ? null : nextLiveClass(schedule, now);
    final Widget body;
    final String title;
    final live = row != null && row.phaseAt(now) == LivePhase.live;
    if (row != null) {
      title = live ? l10n.liveTabLiveNow : l10n.homeNextLiveTitle;
      body = LiveClassCard(
        row: row,
        now: now,
        registered: seats.registeredFor(row),
        onOpen: () => router.go(AppRoutes.liveClass(row.liveClass.id)),
        trailing: LiveAction(row: row, now: now, showJoinNote: true),
      );
    } else if (schedule == null && fallback != null) {
      title = l10n.homeNextLiveTitle;
      body = GroupedList(
        children: [UpcomingRow(item: fallback!, onTap: onOpenFallback)],
      );
    } else {
      return const SizedBox.shrink();
    }

    // Home follows the room too: Join appears when the host opens it and goes when they end it.
    final followRoom =
        row != null && row.liveClass.isRoom && (live || row.liveClass.waitingForHostAt(now));
    return HostWaitPoller(
      active: followRoom,
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Space.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: title,
              icon: AppIcons.live,
              iconColor: live ? context.colors.danger : context.colors.hue(Hue.blue).solid,
              actionLabel: l10n.actionSeeAll,
              onAction: () => router.go(AppRoutes.live),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

/// A row of cards that scrolls sideways, edge to edge, with the page gutter as its inset. The
/// cards share the tallest one's height, which grows with the text size.
class _Carousel extends StatelessWidget {
  const _Carousel({required this.gutter, required this.children});

  final double gutter;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room below for the cards' shadows, which the scroll view would otherwise clip.
      padding: EdgeInsets.fromLTRB(gutter, 2, gutter, Space.s3),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: Space.s3),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One column on a phone, two from the medium breakpoint up (§20).
class _CourseGrid extends StatelessWidget {
  const _CourseGrid({required this.courses, required this.columns, required this.onOpen});

  final List<LearnerCourse> courses;
  final int columns;
  final void Function(LearnerCourse course) onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (courses.length / columns).ceil();
    return Column(
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: Space.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: Space.s3),
                Expanded(
                  child: row * columns + i < courses.length
                      ? LearnerCourseRow(
                          course: courses[row * columns + i],
                          onTap: () => onOpen(courses[row * columns + i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
