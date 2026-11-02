import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_instructors_controller.dart';
import '../widgets/instructor_parts.dart';

/// `/staff/instructors` — the academy's teaching staff (LMS-009). Who is in the list, the counts on
/// the tabs and every expertise tag offered are the academy's own; inviting and editing are offered
/// only to an admin the academy gives `instructors.manage` (§7). A shell body.
class InstructorsScreen extends ConsumerWidget {
  const InstructorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final mayManage = watchCan(ref, Capability.manageInstructors);

    return FabLayout(
      fab: mayManage
          ? AppFab(
              label: l10n.instructorsInviteAction,
              icon: AppIcons.add,
              onPressed: () => GoRouter.of(context).go(AppRoutes.staffInstructorInvite),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () {
          if (mayManage) ref.invalidate(instructorRequestsProvider);
          return ref.refresh(instructorDirectoryProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            gutter,
            Space.s3,
            gutter,
            mayManage ? FabLayout.clearance : Space.s6,
          ),
          children: [
            if (mayManage) const _PendingRequests(),
            const _Filters(),
            const SizedBox(height: Space.s4),
            AsyncView<InstructorDirectory>(
              value: ref.watch(instructorDirectoryProvider),
              onRetry: () => ref.invalidate(instructorDirectoryProvider),
              data: (directory) => _Rows(directory: directory),
            ),
          ],
        ),
      ),
    );
  }
}

/// The directory's head: search and the status tabs in view, the sort and the expertise tag in the
/// Filters sheet behind the button beside the search.
class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(directoryFilterProvider);
    final controller = ref.read(directoryFilterProvider.notifier);
    final directory = ref.watch(instructorDirectoryProvider).value;

    int? countOf(String status) => directory?.countOf(status);

    // Name order is the directory's default; anything else, and any tag, is narrowing it.
    final active = (filter.sort != 'name' ? 1 : 0) + (filter.expertise != null ? 1 : 0);

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.instructorsSearch,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.status,
        onSelected: controller.showStatus,
        options: [
          FilterOption('all', l10n.instructorsTabAll, count: countOf('all')),
          FilterOption('active', l10n.instructorsTabActive, count: countOf('active')),
          FilterOption('invited', l10n.instructorsTabInvited, count: countOf('invited')),
          FilterOption('inactive', l10n.instructorsTabInactive, count: countOf('inactive')),
        ],
      ),
      filters: (_) => const _SheetFilters(),
      activeFilters: active,
      onClearFilters: active == 0
          ? null
          : () => controller
              ..sortBy('name')
              ..withExpertise(null),
    );
  }
}

/// The Filters sheet's fields. They watch the filter themselves, so the sheet follows each change
/// while it is open.
class _SheetFilters extends ConsumerWidget {
  const _SheetFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(directoryFilterProvider);
    final controller = ref.read(directoryFilterProvider.notifier);
    final directory = ref.watch(instructorDirectoryProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSelectField<String>(
          label: l10n.instructorsSortLabel,
          value: filter.sort,
          onChanged: controller.sortBy,
          options: [
            SelectOption('name', l10n.instructorsSortName),
            SelectOption('students', l10n.instructorsSortStudents),
            SelectOption('rating', l10n.instructorsSortRating),
            SelectOption('joined', l10n.instructorsSortJoined),
          ],
        ),
        // The tags offered are the ones the academy actually has in use.
        if (directory?.expertise.isNotEmpty ?? false) ...[
          const SizedBox(height: Space.s3),
          AppSelectField<String>(
            label: l10n.instructorsExpertiseLabel,
            value: filter.expertise ?? '',
            onChanged: (value) => controller.withExpertise(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.instructorsAllExpertise),
              for (final tag in directory!.expertise) SelectOption(tag, tag),
            ],
          ),
        ],
      ],
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.directory});

  final InstructorDirectory directory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(directoryFilterProvider);
    final controller = ref.read(directoryFilterProvider.notifier);

    if (directory.rows.isEmpty) {
      final narrowed = filter.search != null || filter.expertise != null || filter.status != 'all';
      return Padding(
        padding: const EdgeInsets.only(top: Space.s5),
        child: narrowed
            ? EmptyState.noMatches(
                onClearFilters: () {
                  controller
                    ..searchFor(null)
                    ..withExpertise(null)
                    ..showStatus('all');
                },
              )
            : EmptyState(title: l10n.instructorsEmptyTitle, message: l10n.instructorsEmptyBody),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in directory.rows) ...[
          InstructorCard(
            row: row,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffInstructor(row.instructor.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
      ],
    );
  }
}

/// Pending instructor requests (D34): people who registered to teach here and wait for this admin.
/// Shown only while one is waiting; approving makes them staff who can sign in, rejecting keeps
/// them out. Both are the academy's decisions, scoped to it by the server.
class _PendingRequests extends ConsumerStatefulWidget {
  const _PendingRequests();

  @override
  ConsumerState<_PendingRequests> createState() => _PendingRequestsState();
}

class _PendingRequestsState extends ConsumerState<_PendingRequests> {
  String? _busy;

  Future<void> _decide(InstructorRequest request, {required bool approve}) async {
    final l10n = context.l10n;
    if (!approve) {
      final sure = await showConfirmDialog(
        context,
        title: l10n.instructorRequestRejectTitle(request.name),
        message: l10n.instructorRequestRejectBody,
        confirmLabel: l10n.instructorRequestReject,
      );
      if (!sure || !mounted) return;
    }
    setState(() => _busy = request.id);
    final decisions = ref.read(instructorRequestDecisionsProvider);
    final refused = approve
        ? await decisions.approve(request.id)
        : await decisions.reject(request.id);
    if (!mounted) return;
    setState(() => _busy = null);
    showAppSnackbar(
      context,
      refused != null
          ? refused.message ?? l10n.stateErrorBody
          : approve
          ? l10n.instructorRequestApproved(request.name)
          : l10n.instructorRequestRejected(request.name),
      tone: refused != null
          ? SnackTone.error
          : approve
          ? SnackTone.success
          : SnackTone.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final requests = ref.watch(instructorRequestsProvider).value ?? const <InstructorRequest>[];
    if (requests.isEmpty) return const SizedBox.shrink();
    final waiting = context.colors.tone(Tone.warn);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: '${l10n.instructorRequestsTitle} (${requests.length})',
            icon: AppIcons.instructor,
            iconColor: waiting.solid,
          ),
          for (final r in requests) ...[
            StripCard(
              strip: waiting,
              stripIcon: AppIcons.time,
              stripLabel: [
                if (r.requestedAt != null)
                  l10n.instructorRequestRegistered(DatesIst.date(r.requestedAt!)),
                l10n.instructorRequestPending,
              ].join(' · '),
              title: r.name,
              subtitle: r.email,
              footer: Wrap(
                spacing: Space.s2,
                runSpacing: Space.s2,
                children: [
                  AppButton(
                    label: l10n.instructorRequestApprove,
                    busy: _busy == r.id,
                    onPressed: _busy == null ? () => _decide(r, approve: true) : null,
                  ),
                  AppButton(
                    label: l10n.instructorRequestReject,
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy == null ? () => _decide(r, approve: false) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s3),
          ],
        ],
      ),
    );
  }
}
