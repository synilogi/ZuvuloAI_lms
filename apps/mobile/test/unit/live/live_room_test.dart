import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/platform/live_room.dart';
import 'package:syniastrolms_mobile/shared/domain/live_class.dart';

/// What the app hands the Jitsi SDK, and what it hears back — without a camera or a native view.
void main() {
  LiveRoomJoin join({required bool moderator, String? jwt}) => LiveRoomJoin.fromJson({
    'provider': jwt == null ? 'jitsi' : 'jaas',
    'domain': jwt == null ? 'meet.jit.si' : '8x8.vc',
    'room': 'vpaas-magic-cookie-1/shubh-abc',
    'jwt': ?jwt,
    'subject': 'Reading dignities',
    'displayName': moderator ? 'Dr. Meenakshi Iyer' : 'Ananya Rao',
    'email': moderator ? 'host@example.test' : 'learner@example.test',
    'moderator': moderator,
    'recording': true,
  });

  group('who the room is told about', () {
    test('a learner is named, and their e-mail address stays with the academy', () {
      final info = jitsiUserInfoFor(join(moderator: false, jwt: 'signed'));
      expect(info.displayName, 'Ananya Rao');
      expect(info.email, isNull);
      // On a public server too: an address there would only fetch an avatar.
      expect(jitsiUserInfoFor(join(moderator: false)).email, isNull);
    });

    test('the host keeps the address the academy sent', () {
      expect(jitsiUserInfoFor(join(moderator: true)).email, 'host@example.test');
    });

    test('the options carry the room, the token and what the role may do', () {
      final learner = jitsiOptionsFor(join(moderator: false, jwt: 'signed'));
      expect(learner.serverURL, 'https://8x8.vc');
      expect(learner.room, 'vpaas-magic-cookie-1/shubh-abc');
      expect(learner.token, 'signed');
      expect(learner.userInfo?.email, isNull);
      expect(learner.configOverrides?['startWithAudioMuted'], isTrue);
      final flags = learner.featureFlags!.values.toList();
      expect(flags, isNotEmpty);
    });
  });

  group('hearing the room close', () {
    test('an error from the video service is a lost connection', () {
      final closed = <bool>[];
      final listener = jitsiListenerFor(({connectionLost = false}) => closed.add(connectionLost));

      listener.conferenceTerminated?.call(
        'https://meet.jit.si/shubh-abc',
        'connection.droppedError',
      );

      expect(closed, [true]);
    });

    test('leaving is not', () {
      final closed = <bool>[];
      final listener = jitsiListenerFor(({connectionLost = false}) => closed.add(connectionLost));

      listener.conferenceTerminated?.call('https://meet.jit.si/shubh-abc', null);
      listener.readyToClose?.call();

      expect(closed, [false, false]);
    });

    test('the screen behind hears it once, however many events say so', () {
      final closed = <bool>[];
      final close = closeOnce(({connectionLost = false}) => closed.add(connectionLost));
      final listener = jitsiListenerFor(close);

      listener.conferenceTerminated?.call('https://meet.jit.si/shubh-abc', 'conference.failed');
      listener.readyToClose?.call();
      close();

      expect(closed, [true]);
    });
  });
}
