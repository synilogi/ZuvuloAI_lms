import '../../../core/errors/app_failure.dart';
import '../../../shared/domain/user_profile.dart';

/// Why the app is showing signed-out screens — it decides the message on the sign-in screen (§6).
enum SignedOutReason {
  /// Never signed in (a first launch, or a launch with no stored session).
  none,

  /// The person signed out on purpose. Where they were is not where the next person to sign in on
  /// this device is going, so no `next` is kept (LIVE E2E AUTH-014).
  signedOut,

  /// A 401 on a request that carried a token, or no valid session at launch.
  expired,

  /// The person deleted their account. Like [signedOut], where they were is not kept.
  deleted,

  /// The server refused with an account message (deactivated, suspended, inactive instructor).
  refused,
}

/// The session, as the whole app reads it (§6). The token itself never appears here.
sealed class SessionState {
  const SessionState();

  UserProfile? get user => switch (this) {
    SessionSignedIn(:final profile) => profile,
    _ => null,
  };
}

/// Restoring at launch.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// The session could not be restored because the server could not be reached. **The token is
/// kept** — nobody is signed out for being offline (§6).
class SessionUnavailable extends SessionState {
  const SessionUnavailable(this.failure);

  final AppFailure failure;
}

/// Signed out. [message] is the server's own words when it refused the account.
class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.reason = SignedOutReason.none, this.message});

  final SignedOutReason reason;
  final String? message;
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.profile);

  final UserProfile profile;
}

/// A platform super admin: the API signs them in, the app does not serve them (§6).
class SessionUnsupportedRole extends SessionState {
  const SessionUnsupportedRole();
}
