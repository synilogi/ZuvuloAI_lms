import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/certificates/certificates.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  Future<void> pumpRanks(WidgetTester tester) => pumpPublic(
    tester,
    const Scaffold(body: SafeArea(child: RanksScreen())),
    adapter: adapter,
    signedInAs: learner(),
    size: const Size(400, 1400),
  );

  testWidgets('the ladder shows the standing the academy gave, and each rank in order', (
    tester,
  ) async {
    adapter.enqueueJson(fixture('learning/rank-ladder.json'));

    await pumpRanks(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RankRing), findsOneWidget);
    expect(find.text('Rank I · Beginner'), findsWidgets);
    expect(find.text('Where you are now'), findsOneWidget);
    expect(find.text('Next rank'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.byType(RankStepCard), findsNWidgets(3));
    // The requirement is the academy's; no figure is claimed for how far along the learner is.
    expect(find.text('Courses completed: 2'), findsOneWidget);
    expect(find.text('Courses completed: 4'), findsOneWidget);
    expect(find.text('Your LMS does not publish how far along you are.'), findsOneWidget);
  });

  testWidgets('the lowest rank stands in when the academy has not placed the learner', (
    tester,
  ) async {
    final ladder = fixture('learning/rank-ladder.json')! as Map<String, dynamic>;
    adapter.enqueueJson({
      ...ladder,
      'standing': const {'rankId': ''},
    });

    await pumpRanks(tester);
    await tester.pumpAndSettle();

    expect(find.text('Where you are now'), findsOneWidget);
    expect(
      tester.widget<RankRing>(find.byType(RankRing)).rankName,
      'Rank I · Beginner',
      reason: 'the ring shows the standing, not a guess',
    );
  });

  testWidgets('an academy with no ladder says so', (tester) async {
    adapter.enqueueJson(const <String, Object>{});

    await pumpRanks(tester);
    await tester.pumpAndSettle();

    expect(find.text('No ranks yet'), findsOneWidget);
    expect(find.byType(RankStepCard), findsNothing);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..enqueueJson(fixture('learning/rank-ladder.json'));

    await pumpRanks(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(RankStepCard), findsNWidgets(3));
  });
}
