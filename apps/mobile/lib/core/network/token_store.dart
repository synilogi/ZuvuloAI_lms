/// Where the session token lives. FLUTTER-004 implements it over `flutter_secure_storage`; the
/// network layer only reads it (to attach the bearer) and never sees how it is stored.
abstract interface class TokenStore {
  Future<String?> read();
}
