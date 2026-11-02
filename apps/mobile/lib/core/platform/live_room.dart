import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../../shared/domain/live_class.dart';

/// Opens the academy's built-in live room — the Jitsi Meet SDK's own full-screen activity, on the
/// server, room and token the API handed over (`POST /live/:id/start` or `/join`). A platform
/// capability behind a provider, so a test sees what would open without a camera.
///
/// [onClosed] runs once when the person leaves, is sent out when the host ends the class, or the
/// connection drops — the screen behind then reads the class again. `connectionLost` is true when
/// the video service ended the conference with an error rather than the person leaving.
typedef OpenLiveRoom = Future<void> Function(LiveRoomJoin room, {LiveRoomClosed? onClosed});

/// How the room closed: [connectionLost] when the video service reported an error.
typedef LiveRoomClosed = void Function({bool connectionLost});

final openLiveRoomProvider = Provider<OpenLiveRoom>((ref) => openJitsiRoom);

final _jitsi = JitsiMeet();

Future<void> openJitsiRoom(LiveRoomJoin room, {LiveRoomClosed? onClosed}) async {
  final close = closeOnce(onClosed);
  final response = await _jitsi.join(jitsiOptionsFor(room), jitsiListenerFor(close));
  if (!response.isSuccess) {
    close();
    throw LiveRoomUnavailable(response.message ?? '${response.error ?? ''}');
  }
}

/// What the room is told about the person. A learner is named and nothing more: on JaaS the token
/// the API signed already carries who they are, and on a public server an e-mail address would only
/// go to the video service for an avatar. The host's own address stays, as the API sends it.
JitsiMeetUserInfo jitsiUserInfoFor(LiveRoomJoin room) =>
    JitsiMeetUserInfo(displayName: room.displayName, email: room.moderator ? room.email : null);

/// [onClosed], run once however many of the SDK's events say the room closed.
LiveRoomClosed closeOnce(LiveRoomClosed? onClosed) {
  var closed = false;
  return ({bool connectionLost = false}) {
    if (closed) return;
    closed = true;
    onClosed?.call(connectionLost: connectionLost);
  };
}

/// Hears the room close, and whether it closed on an error — the conference failed or the
/// connection dropped — rather than the person leaving. The SDK's error was dropped before, so a
/// learner thrown out of the class was told nothing.
JitsiMeetEventListener jitsiListenerFor(LiveRoomClosed close) => JitsiMeetEventListener(
  conferenceTerminated: (_, error) => close(connectionLost: error != null),
  readyToClose: close,
);

/// The SDK's options for [room]: its server, name and token, and what the room offers this person.
JitsiMeetConferenceOptions jitsiOptionsFor(LiveRoomJoin room) => JitsiMeetConferenceOptions(
  serverURL: room.serverUrl.toString(),
  room: room.room,
  token: room.jwt,
  configOverrides: {
    'subject': room.subject,
    // The host comes in ready to teach; learners join quiet and turn things on to ask.
    'startWithAudioMuted': !room.moderator,
    'startWithVideoMuted': !room.moderator,
  },
  featureFlags: {
    FeatureFlags.welcomePageEnabled: false,
    FeatureFlags.preJoinPageEnabled: false,
    // Nobody is invited or let in from inside the room: the academy decides who joins.
    FeatureFlags.inviteEnabled: false,
    FeatureFlags.addPeopleEnabled: false,
    FeatureFlags.meetingPasswordEnabled: false,
    FeatureFlags.securityOptionEnabled: false,
    FeatureFlags.serverUrlChangeEnabled: false,
    FeatureFlags.calenderEnabled: false,
    FeatureFlags.callIntegrationEnabled: false,
    FeatureFlags.liveStreamingEnabled: false,
    // Screens are shared from the web room. The app ships without the SDK's screen-capture
    // service (AndroidManifest.xml), so the button must not be offered here.
    FeatureFlags.androidScreenSharingEnabled: false,
    FeatureFlags.recordingEnabled: room.moderator && room.recording,
    FeatureFlags.kickOutEnabled: room.moderator,
    FeatureFlags.raiseHandEnabled: true,
    FeatureFlags.chatEnabled: true,
    FeatureFlags.pipEnabled: true,
  },
  userInfo: jitsiUserInfoFor(room),
);

/// The room could not be opened on this device.
class LiveRoomUnavailable implements Exception {
  const LiveRoomUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'LiveRoomUnavailable: $reason';
}
