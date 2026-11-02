import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/app.dart';
import '../../../../app/routing/app_router.dart';
import '../../../../app/routing/routes.dart';
import '../../../../core/platform/app_info.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/platform/support.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../../certificates/certificates.dart';
import '../../../learner_home/learner_home.dart' show coursesForTab, learnerCoursesProvider;
import '../widgets/activity_list.dart';

/// `/profile` and `/staff/profile` — who is signed in (from `GET /auth/me`, never from local
/// state), what a learner has been doing, and the way to everything else (§26). A shell body.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentUserProvider);
    if (profile == null) return const SizedBox.shrink();
    final learner = profile.role == UserRole.student;
    final staff = profile.role == UserRole.instructor || profile.role == UserRole.admin;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s6),
      children: [
        _IdentityCard(profile: profile),
        if (learner) ...[
          const SizedBox(height: Space.s4),
          const _LearnerStats(),
          const SizedBox(height: Space.sectionGap),
          // Carries its own gap below: it is left out when the learner has no rank yet.
          const _Standing(),
          // What the learner has earned and been told, now that Profile is a tab of its own.
          GroupedList(
            title: l10n.profileGroupLearning,
            children: [
              AppListTile(
                title: l10n.navMyCourses,
                subtitle: l10n.profileMyCoursesSubtitle,
                leading: const HueTile(icon: AppIcons.learning, hue: Hue.violet),
                showChevron: true,
                onTap: () =>
                    GoRouter.of(context).go(AppRoutes.myLearning(MyLearningTab.inProgress)),
              ),
              AppListTile(
                title: l10n.purchasesTitle,
                subtitle: l10n.purchasesSubtitle,
                leading: const HueTile(icon: AppIcons.billing, hue: Hue.orange),
                showChevron: true,
                onTap: () => GoRouter.of(context).go(AppRoutes.profilePurchases),
              ),
              AppListTile(
                title: l10n.navCertificates,
                leading: const HueTile(icon: AppIcons.certificate, hue: Hue.gold),
                showChevron: true,
                onTap: () => GoRouter.of(context).go(AppRoutes.certificates),
              ),
              AppListTile(
                title: l10n.navRanks,
                leading: const HueTile(icon: AppIcons.rank, hue: Hue.green),
                showChevron: true,
                onTap: () => GoRouter.of(context).go(AppRoutes.ranks),
              ),
              AppListTile(
                title: l10n.navNotifications,
                leading: const HueTile(icon: AppIcons.notifications, hue: Hue.blue),
                showChevron: true,
                onTap: () => GoRouter.of(context).go(AppRoutes.notifications),
              ),
            ],
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.profileActivityTitle,
            icon: AppIcons.trendUp,
            iconColor: context.colors.hue(Hue.green).solid,
          ),
          const ActivityFeed(),
        ],
        const SizedBox(height: Space.sectionGap),
        GroupedList(
          title: l10n.profileGroupAccount,
          children: [
            AppListTile(
              title: l10n.notificationPrefsTitle,
              leading: const HueTile(icon: AppIcons.notifications, hue: Hue.blue),
              showChevron: true,
              onTap: () => GoRouter.of(context).go(
                staff ? AppRoutes.staffNotificationPreferences : AppRoutes.notificationPreferences,
              ),
            ),
            AppListTile(
              title: l10n.settingsTitle,
              leading: const IconTile(icon: AppIcons.settings, tone: Tone.neutral),
              showChevron: true,
              onTap: () => GoRouter.of(
                context,
              ).go(staff ? AppRoutes.staffProfileSettings : AppRoutes.profileSettings),
            ),
          ],
        ),
        const SizedBox(height: Space.s5),
        GroupedList(
          title: l10n.profileGroupSupport,
          children: [
            AppListTile(
              title: l10n.actionHelpCentre,
              leading: const HueTile(icon: AppIcons.help, hue: Hue.blue),
              showChevron: true,
              onTap: () => GoRouter.of(context).go(staff ? AppRoutes.staffHelp : AppRoutes.help),
            ),
            AppListTile(
              title: l10n.profileContactSupport,
              subtitle: kSupportEmail,
              leading: const HueTile(icon: AppIcons.email, hue: Hue.pink),
              showChevron: true,
              onTap: () => _contactSupport(context, ref),
            ),
          ],
        ),
        const SizedBox(height: Space.s5),
        GroupedList(
          title: l10n.profileGroupAbout,
          children: [
            AppListTile(
              title: l10n.legalPrivacyTitle,
              leading: const IconTile(icon: AppIcons.file, tone: Tone.neutral),
              showChevron: true,
              onTap: () => GoRouter.of(context).go(AppRoutes.privacy),
            ),
            AppListTile(
              title: l10n.legalTermsTitle,
              leading: const IconTile(icon: AppIcons.file, tone: Tone.neutral),
              showChevron: true,
              onTap: () => GoRouter.of(context).go(AppRoutes.terms),
            ),
            AppListTile(
              title: l10n.profileAboutTitle,
              leading: const IconTile(icon: AppIcons.info, tone: Tone.neutral),
              showChevron: true,
              onTap: () => showAboutThisApp(context, ref),
            ),
            // Dev builds only: the component gallery lives behind a dev route (§24).
            for (final route in ref.watch(devRoutesProvider).keys)
              AppListTile(
                title: l10n.devComponentGallery,
                leading: const IconTile(icon: AppIcons.rocket, tone: Tone.warn),
                showChevron: true,
                onTap: () => GoRouter.of(context).go(route),
              ),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        AppButton(
          label: l10n.actionSignOut,
          variant: AppButtonVariant.destructiveOutline,
          expand: true,
          onPressed: () => _signOut(context, ref),
        ),
        const SizedBox(height: Space.s2),
        // Google Play's account-deletion policy: a learner deletes their own account here; a staff
        // account belongs to its academy, which closes it, so staff are told who to ask.
        AppButton(
          label: l10n.deleteAccountTitle,
          variant: AppButtonVariant.tertiary,
          size: AppButtonSize.sm,
          onPressed: () => learner
              ? GoRouter.of(context).go(AppRoutes.profileDeleteAccount)
              : _explainStaffDeletion(context, ref),
        ),
      ],
    );
  }

  void _contactSupport(BuildContext context, WidgetRef ref) {
    ref.read(openExternalLinkProvider)(supportEmailLink(subject: context.l10n.supportEmailSubject));
  }

  Future<void> _explainStaffDeletion(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final contact = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: l10n.deleteAccountStaffTitle,
        message: l10n.deleteAccountStaffBody,
        confirmLabel: l10n.profileContactSupport,
      ),
    );
    if (contact == true && context.mounted) _contactSupport(context, ref);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: l10n.profileSignOutConfirmTitle,
        message: l10n.profileSignOutConfirmBody,
        confirmLabel: l10n.actionSignOut,
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionControllerProvider.notifier).signOut();
  }
}

/// Who is signed in, as the academy knows them, on the brand's own gradient.
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final roleLabel = switch (profile.role) {
      UserRole.student => l10n.roleLearner,
      UserRole.instructor => l10n.roleInstructor,
      UserRole.admin => l10n.roleAdmin,
      UserRole.superadmin || UserRole.unknown => profile.descriptor,
    };
    final quiet = c.onAccent.withValues(alpha: 0.85);
    final radius = BorderRadius.circular(Radii.xl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.accent, c.accentHover],
        ),
        boxShadow: context.shadows.e2,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.s4, Space.s5, Space.s4, Space.s4),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.onAccent.withValues(alpha: 0.6), width: 3),
              ),
              child: AvatarInitials(name: profile.name, size: AvatarSizes.xl),
            ),
            const SizedBox(height: Space.s3),
            Text(
              profile.name,
              style: type.titleL.copyWith(color: c.onAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              profile.email,
              style: type.bodyS.copyWith(color: quiet),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.s3),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.s2,
              runSpacing: Space.s1,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.onAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: 3),
                    child: Text(
                      roleLabel,
                      style: type.caption.copyWith(color: c.onAccent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (profile.descriptor.isNotEmpty && profile.descriptor != roleLabel)
                  Text(profile.descriptor, style: type.bodyS.copyWith(color: quiet)),
              ],
            ),
            const SizedBox(height: Space.s4),
            // The academy offers no way to change a name, an e-mail or a password while signed in
            // (B3); the only door it has is the reset link it sends by e-mail.
            AppButton(
              label: l10n.profileChangePassword,
              variant: AppButtonVariant.inverse,
              size: AppButtonSize.sm,
              icon: AppIcons.lock,
              onPressed: () => GoRouter.of(
                context,
              ).go('${AppRoutes.forgotPassword}?email=${Uri.encodeQueryComponent(profile.email)}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A learner's figures as three tiles that open what they count: courses in progress, courses
/// completed, certificates issued — each the server's own list, counted. A list that has not come
/// back (or could not be read) leaves its tile out rather than showing a wrong zero.
class _LearnerStats extends ConsumerWidget {
  const _LearnerStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final courses = ref.watch(learnerCoursesProvider).value;
    final wallet = ref.watch(certificateWalletProvider).value;
    final tiles = [
      if (courses != null) ...[
        _StatTile(
          value: coursesForTab(courses, MyLearningTab.inProgress).length,
          label: l10n.statusInProgress,
          icon: AppIcons.learning,
          hue: Hue.violet,
          onTap: () => router.go(AppRoutes.myLearning(MyLearningTab.inProgress)),
        ),
        _StatTile(
          value: coursesForTab(courses, MyLearningTab.completed).length,
          label: l10n.statusCompleted,
          icon: AppIcons.success,
          hue: Hue.green,
          onTap: () => router.go(AppRoutes.myLearning(MyLearningTab.completed)),
        ),
      ],
      if (wallet != null)
        _StatTile(
          value: wallet.issued.length,
          label: l10n.navCertificates,
          icon: AppIcons.certificate,
          hue: Hue.gold,
          onTap: () => router.go(AppRoutes.certificates),
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.s2),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.hue,
    required this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final Hue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(hue);
    return AppCard(
      onTap: onTap,
      color: h.soft,
      padding: const EdgeInsets.all(Space.s3),
      semanticLabel: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: IconSizes.md, color: h.solid),
          const SizedBox(height: Space.s2),
          Text(
            '$value',
            style: context.type.numeral.copyWith(
              fontSize: context.type.titleL.fontSize,
              color: h.ink,
            ),
          ),
          Text(label, style: context.type.caption.copyWith(color: context.colors.text)),
        ],
      ),
    );
  }
}

/// Where the learner stands on the academy's ladder.
class _Standing extends ConsumerWidget {
  const _Standing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ladder = ref.watch(rankLadderProvider).value;
    final current = ladder?.current;
    if (current == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.profileRankTitle,
          icon: AppIcons.rank,
          iconColor: context.colors.hue(Hue.gold).solid,
          actionLabel: l10n.navRanks,
          onAction: () => GoRouter.of(context).go(AppRoutes.ranks),
        ),
        AppCard(
          onTap: () => GoRouter.of(context).go(AppRoutes.ranks),
          color: context.colors.hue(Hue.gold).soft,
          child: Row(
            children: [
              Container(
                width: AvatarSizes.lg,
                height: AvatarSizes.lg,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.hue(Hue.gold).solid, width: 2),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppIcons.rank,
                  size: IconSizes.xl,
                  color: context.colors.hue(Hue.gold).solid,
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: context.type.titleS.copyWith(color: context.colors.hue(Hue.gold).ink),
                    ),
                    if (current.descriptor.isNotEmpty) ...[
                      const SizedBox(height: Space.s1),
                      Text(
                        current.descriptor,
                        style: context.type.bodyS.copyWith(color: context.colors.text),
                      ),
                    ],
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: context.colors.muted),
            ],
          ),
        ),
        const SizedBox(height: Space.sectionGap),
      ],
    );
  }
}

/// The app's own About: what this build is, and the licences of what it is built from.
Future<void> showAboutThisApp(BuildContext context, WidgetRef ref) async {
  // Awaited, not read: nothing else loads the package info, so a plain read was still loading the
  // first time About was opened and the version was left out (LIVE E2E PROF-003).
  PackageInfo? info;
  try {
    info = await ref.read(appInfoProvider.future);
  } on Object {
    info = null; // The dialog still opens; it just cannot name the version.
  }
  if (!context.mounted) return;
  final l10n = context.l10n;
  showAboutDialog(
    context: context,
    applicationName: kAppName,
    applicationVersion: info == null
        ? null
        : l10n.profileAboutVersion(info.version, info.buildNumber),
    applicationLegalese: l10n.appTagline,
  );
}
