import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_courses/staff_courses.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

UserProfile _instructor() => const UserProfile(
  id: 'u_staff',
  name: 'Dr. Meenakshi Iyer',
  email: 'staff@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Answers by path, so a test never depends on the order the providers settle in.
  void answering({Object? action, int actionStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method == 'POST') {
        return FakeAdapter.jsonResponse(
          action ??
              ((fixture('staff/courses.json')! as Map<String, dynamic>)['rows']! as List).first,
          status: actionStatus,
        );
      }
      if (options.path == '/categories') {
        return FakeAdapter.jsonResponse(fixture('staff/categories.json'));
      }
      if (options.path.endsWith('/chapters/stats')) {
        return FakeAdapter.jsonResponse(fixture('staff/chapter-stats.json'));
      }
      if (options.path.endsWith('/stats')) {
        return FakeAdapter.jsonResponse(fixture('staff/course-stats.json'));
      }
      return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
    };
  }

  /// The screens watch the action state while an action runs, so a container that stands in for a
  /// screen listens to it too — an unwatched auto-dispose provider would be gone mid-request.
  ProviderContainer containerFor(UserProfile profile) {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: profile,
        child: const SizedBox.shrink(),
      ).overrides,
    );
    addTearDown(container.dispose);
    container.listen(courseActionProvider, (_, _) {});
    return container;
  }

  test('the list starts at the first page, sorted the way the screen opens', () async {
    answering();
    final container = containerFor(_admin());
    container.listen(staffCoursesProvider, (_, _) {});

    await container.read(staffCoursesProvider.future);

    expect(adapter.lastRequest.queryParameters, {'sort': 'updated', 'page': 1, 'pageSize': 20});
  });

  test('narrowing the list sends the filter and goes back to the first page', () async {
    answering();
    final container = containerFor(_admin());
    container.listen(staffCoursesProvider, (_, _) {});
    await container.read(staffCoursesProvider.future);

    container.read(courseFilterProvider.notifier).showPage(3);
    await container.read(staffCoursesProvider.future);
    expect(adapter.lastRequest.queryParameters['page'], 3);

    container.read(courseFilterProvider.notifier).showStatus('draft');
    await container.read(staffCoursesProvider.future);

    expect(adapter.lastRequest.queryParameters['status'], 'draft');
    expect(adapter.lastRequest.queryParameters['page'], 1, reason: 'a new filter is a new list');
  });

  test('"all" is the app\'s word for no filter, so the route is asked for no status', () async {
    answering();
    final container = containerFor(_admin());
    container.listen(staffCoursesProvider, (_, _) {});

    await container.read(staffCoursesProvider.future);

    expect(adapter.lastRequest.queryParameters.containsKey('status'), isFalse);
  });

  test('an instructor never sends an instructorId, whatever the filter holds', () async {
    answering();
    final container = containerFor(_instructor());
    container.listen(staffCoursesProvider, (_, _) {});
    await container.read(staffCoursesProvider.future);

    container.read(courseFilterProvider.notifier).byInstructor('someone-else');
    await container.read(staffCoursesProvider.future);

    expect(adapter.lastRequest.queryParameters.containsKey('instructorId'), isFalse);
  });

  test('an admin may narrow the list to one instructor', () async {
    answering();
    final container = containerFor(_admin());
    container.listen(staffCoursesProvider, (_, _) {});
    await container.read(staffCoursesProvider.future);

    container.read(courseFilterProvider.notifier).byInstructor('ins_1');
    await container.read(staffCoursesProvider.future);

    expect(adapter.lastRequest.queryParameters['instructorId'], 'ins_1');
  });

  test('clearing the search drops it from the request rather than sending nothing', () async {
    answering();
    final container = containerFor(_admin());
    container.listen(staffCoursesProvider, (_, _) {});
    container.read(courseFilterProvider.notifier).searchFor('  nakshatra  ');
    await container.read(staffCoursesProvider.future);
    expect(adapter.lastRequest.queryParameters['search'], 'nakshatra');

    container.read(courseFilterProvider.notifier).searchFor('   ');
    await container.read(staffCoursesProvider.future);

    expect(adapter.lastRequest.queryParameters.containsKey('search'), isFalse);
  });

  test('a published course re-reads the list and the course itself', () async {
    answering();
    final container = containerFor(_admin());
    var listReads = 0;
    container.listen(staffCoursesProvider, (_, _) {
      listReads++;
    });
    await container.read(staffCoursesProvider.future);

    final published = await container.read(courseActionProvider.notifier).publish('c1');
    await container.read(staffCoursesProvider.future);

    expect(published, isTrue);
    expect(container.read(courseActionProvider).busy, isFalse);
    expect(container.read(courseActionProvider).checklist, isEmpty);
    expect(listReads, greaterThan(1), reason: 'the counts and the rows have moved');
  });

  test('a refused publish keeps the academy\'s checklist, not a generic error', () async {
    answering(action: fixture('errors/publish-checklist.json'), actionStatus: 409);
    final container = containerFor(_admin());

    final published = await container.read(courseActionProvider.notifier).publish('c1');
    final state = container.read(courseActionProvider);

    expect(published, isFalse);
    expect(state.busy, isFalse);
    expect(state.checklist, hasLength(6));
    expect(state.checklist.first.label, 'Title and subtitle');
    expect(state.failure, isNull, reason: 'the checklist is the explanation');
  });

  test('a refusal with no checklist is kept in the academy\'s own words', () async {
    answering(
      action: const {
        'message': 'This academy asks an admin to review courses before they go live.',
      },
      actionStatus: 403,
    );
    final container = containerFor(_instructor());

    final published = await container.read(courseActionProvider.notifier).publish('c1');
    final state = container.read(courseActionProvider);

    expect(published, isFalse);
    expect(state.checklist, isEmpty);
    expect(state.failure, isA<ForbiddenFailure>());
    expect(state.failure!.message, contains('review courses'));
  });

  test('a limit the plan has used up is kept as an entitlement refusal', () async {
    answering(
      action: const {'message': 'Your plan allows 10 courses.', 'code': 'LIMIT_REACHED'},
      actionStatus: 403,
    );
    final container = containerFor(_admin());

    final restored = await container.read(courseActionProvider.notifier).restore('c1');

    expect(restored, isFalse);
    expect(
      container.read(courseActionProvider).failure,
      isA<EntitlementFailure>().having(
        (f) => f.problem,
        'problem',
        EntitlementProblem.limitReached,
      ),
    );
  });

  test('forgetting the academy\'s answer clears both the checklist and the refusal', () async {
    answering(action: fixture('errors/publish-checklist.json'), actionStatus: 409);
    final container = containerFor(_admin());
    await container.read(courseActionProvider.notifier).publish('c1');
    expect(container.read(courseActionProvider).checklist, isNotEmpty);

    container.read(courseActionProvider.notifier).clearAnswer();

    expect(container.read(courseActionProvider).checklist, isEmpty);
    expect(container.read(courseActionProvider).failure, isNull);
  });

  test('a second action is ignored while the first is still in flight', () async {
    answering();
    final container = containerFor(_admin());

    final first = container.read(courseActionProvider.notifier).publish('c1');
    final second = container.read(courseActionProvider.notifier).archive('c1');

    expect(await second, isFalse, reason: 'one decision at a time');
    expect(await first, isTrue);
    expect(adapter.requests.where((r) => r.method == 'POST'), hasLength(1));
  });

  test(
    'a category read the academy refuses leaves the filter empty, not the list broken',
    () async {
      adapter.handler = (options) async => options.path == '/categories'
          ? FakeAdapter.jsonResponse(const {'message': 'No.'}, status: 403)
          : FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      final container = containerFor(_instructor());

      expect(await container.read(courseCategoriesProvider.future), isEmpty);
      expect((await container.read(staffCoursesProvider.future)).rows, isNotEmpty);
    },
  );
}
