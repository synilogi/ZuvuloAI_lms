import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/pump.dart';

/// Going into a class: a black screen with a small loader covers the hand-over to the Jitsi SDK,
/// cannot be dismissed, and goes away when the opening is done — on success and on failure alike.
void main() {
  Future<BuildContext> host(WidgetTester tester) async {
    late BuildContext captured;
    await pumpThemed(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const Text('Live schedule');
        },
      ),
    );
    return captured;
  }

  testWidgets('shows the black joining screen while the room opens, then removes it', (tester) async {
    final context = await host(tester);
    final opening = Completer<bool>();
    final result = withLiveRoomJoining(context, () => opening.future);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LiveRoomJoiningView), findsOneWidget);
    expect(find.text('Connecting to the class…'), findsOneWidget);
    final loader = tester.getSize(find.byType(CircularProgressIndicator));
    expect(loader.width, lessThanOrEqualTo(24), reason: 'a small loader, not the full-screen spinner');

    // Back does not dismiss it: the room is still being opened.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(LiveRoomJoiningView), findsOneWidget);

    opening.complete(true);
    expect(await result, isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(LiveRoomJoiningView), findsNothing);
    expect(find.text('Live schedule'), findsOneWidget);
  });

  testWidgets('goes away when opening fails, and passes the error on', (tester) async {
    final context = await host(tester);
    final opening = Completer<bool>();
    final result = withLiveRoomJoining(context, () => opening.future);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LiveRoomJoiningView), findsOneWidget);

    opening.completeError(StateError('room failed'));
    await expectLater(result, throwsStateError);
    await tester.pumpAndSettle();
    expect(find.byType(LiveRoomJoiningView), findsNothing);
  });
}
