import 'package:flutter/material.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../assignments/assignments.dart';
import 'assessments_screen.dart';

/// The two halves of the learner's Tests tab.
enum TestsSegment {
  tests(AppRoutes.assessments),
  assignments(AppRoutes.assignments);

  const TestsSegment(this.route);

  /// Each half keeps its own route, so a link to `/assignments` still lands on it.
  final String route;
}

/// `/assessments` and `/assignments` — the learner's Tests tab: every quiz and every piece of
/// coursework across their courses, one switch apart. Each list is the server's own, in the order
/// it sent. A shell body: the shell draws the frame.
class TestsScreen extends StatelessWidget {
  const TestsScreen({required this.segment, super.key});

  final TestsSegment segment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.s3),
        FilterChipBar<TestsSegment>(
          options: [
            FilterOption(TestsSegment.tests, l10n.navTests),
            FilterOption(TestsSegment.assignments, l10n.navAssignments),
          ],
          selected: segment,
          onSelected: (next) => goWithin(context, next.route, replace: true),
        ),
        Expanded(
          child: switch (segment) {
            TestsSegment.tests => const AssessmentsScreen(),
            TestsSegment.assignments => const AssignmentsScreen(),
          },
        ),
      ],
    );
  }
}
