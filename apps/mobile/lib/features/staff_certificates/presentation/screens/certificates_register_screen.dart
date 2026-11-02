import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../application/staff_certificates_controller.dart';
import '../widgets/register_parts.dart';

/// `/staff/certificates` — the academy's credential register (LMS-011 management). An instructor is
/// served only the certificates of courses they teach; the counts, the paging and who is in the list
/// are the academy's (§7). A shell body.
class CertificatesRegisterScreen extends ConsumerWidget {
  const CertificatesRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(certificateRegisterProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          const _Filters(),
          const SizedBox(height: Space.s4),
          AsyncView<CertificateRegister>(
            value: ref.watch(certificateRegisterProvider),
            onRetry: () => ref.invalidate(certificateRegisterProvider),
            data: (register) => _Rows(register: register),
          ),
        ],
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(registerFilterProvider);
    final controller = ref.read(registerFilterProvider.notifier);
    final register = ref.watch(certificateRegisterProvider).value;
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];

    int? countOf(String status) => register?.countOf(status);

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.registerSearch,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.status,
        onSelected: controller.showStatus,
        options: [
          FilterOption('all', l10n.registerTabAll, count: countOf('all')),
          FilterOption('issued', l10n.certificatesTabIssued, count: countOf('issued')),
          FilterOption('pending', l10n.certificatesTabPending, count: countOf('pending')),
          FilterOption('revoked', l10n.registerTabRevoked, count: countOf('revoked')),
        ],
      ),
      // The course is the register's one secondary filter, offered once there are courses to pick.
      filters: courses.isEmpty ? null : (_) => const _SheetFilters(),
      activeFilters: filter.courseId != null ? 1 : 0,
      onClearFilters: filter.courseId == null ? null : () => controller.inCourse(null),
    );
  }
}

/// The Filters sheet's field, watching the filter itself so the sheet follows each change.
class _SheetFilters extends ConsumerWidget {
  const _SheetFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(registerFilterProvider);
    final controller = ref.read(registerFilterProvider.notifier);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];

    return AppSelectField<String>(
      label: l10n.registerCourseLabel,
      value: filter.courseId ?? '',
      onChanged: (value) => controller.inCourse(value.isEmpty ? null : value),
      options: [
        SelectOption('', l10n.registerAllCourses),
        for (final course in courses) SelectOption(course.id, course.title),
      ],
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.register});

  final CertificateRegister register;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(registerFilterProvider);
    final controller = ref.read(registerFilterProvider.notifier);

    if (register.rows.isEmpty) {
      final narrowed = filter.search != null || filter.courseId != null || filter.status != 'all';
      return Padding(
        padding: const EdgeInsets.only(top: Space.s5),
        child: narrowed
            ? EmptyState.noMatches(
                onClearFilters: () {
                  controller
                    ..searchFor(null)
                    ..inCourse(null)
                    ..showStatus('all');
                },
              )
            : EmptyState(title: l10n.registerEmptyTitle, message: l10n.registerEmptyBody),
      );
    }

    final pages = (register.total / registerPageSize).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in register.rows) ...[
          RegisterCard(
            row: row,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffCertificate(row.certificate.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
        PagerRow(page: filter.page, pages: pages, onPage: controller.showPage),
      ],
    );
  }
}
