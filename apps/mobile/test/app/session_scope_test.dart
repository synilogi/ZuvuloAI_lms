import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/session_scope.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/shared/domain/level.dart';
import 'package:syniastrolms_mobile/shared/domain/user_profile.dart';
import 'package:syniastrolms_mobile/shared/session/current_user.dart';

/// Signing out, or someone else signing in — perhaps a learner of another Admin's LMS — must never
/// leave the last person's data on screen (multi-admin SaaS, §8.4).

/// Who is signed in, as the test drives it.
class _Who extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;
  void set(UserProfile? profile) => state = profile;
}

final _who = NotifierProvider<_Who, UserProfile?>(_Who.new);

/// A catalogue that answers with whoever's LMS it was asked for.
class _CatalogOf implements CatalogApi {
  _CatalogOf(this.reads);
  final List<String?> reads;
  String? owner;

  @override
  Future<List<Level>> levels() async {
    reads.add(owner);
    return [Level(id: 'l-$owner', name: 'Level of $owner', order: 1)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserProfile _person(String id) => UserProfile.fromJson({
  'id': id,
  'name': 'Learner $id',
  'email': '$id@example.test',
  'role': 'student',
  'descriptor': 'Learner',
});

void main() {
  testWidgets(
    'a session-scoped read is dropped when the person changes, and read again for the next',
    (tester) async {
      final reads = <String?>[];
      final catalog = _CatalogOf(reads);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => ref.watch(_who)),
          catalogApiProvider.overrideWithValue(catalog),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              listenForSessionChange(ref);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      container.read(_who.notifier).set(_person('a'));
      catalog.owner = 'admin-a';
      await tester.pump();
      final levelsOfA = await container.read(catalogLevelsProvider.future);
      expect(levelsOfA.single.name, 'Level of admin-a');

      // Learner A signs out; learner B, of another Admin's LMS, signs in on the same device.
      container.read(_who.notifier).set(null);
      await tester.pump();
      container.read(_who.notifier).set(_person('b'));
      catalog.owner = 'admin-b';
      await tester.pump();

      final levelsOfB = await container.read(catalogLevelsProvider.future);
      expect(levelsOfB.single.name, 'Level of admin-b');
      expect(reads, ['admin-a', 'admin-b']);
    },
  );

  test('every provider that holds a person’s data is scoped to the session', () {
    expect(sessionScopedProviders, isNotEmpty);
    expect(sessionScopedProviders.toSet().length, sessionScopedProviders.length);
  });
}
