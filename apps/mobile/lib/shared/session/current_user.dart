import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';

/// Who is signed in, for code that must not depend on the auth feature — `core`, shared widgets and
/// the shells (§26). The app overrides it with the session's profile at start-up; it is null while
/// signed out.
final currentUserProvider = Provider<UserProfile?>((ref) => null);
