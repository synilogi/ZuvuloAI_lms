import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dto/verified_certificate.dart';
import '../data/verify_api.dart';

/// The verification result the screens read (§26).
export '../data/dto/verified_certificate.dart';

/// What a credential ID must look like before the app spends a request on it: the API's `id`
/// schema is 1–64 characters. It is sent exactly as typed; only the display upper-cases it
/// (FLUTTER-008 spec).
abstract final class CredentialId {
  static const maxLength = 64;

  static String normalise(String raw) => raw.trim();

  static bool isWellFormed(String raw) {
    final value = normalise(raw);
    return value.isNotEmpty && value.length <= maxLength;
  }
}

/// One verification. Auto-disposed so leaving the result and coming back re-reads it — the
/// academy can revoke a certificate at any time.
final verificationProvider = FutureProvider.family<VerifiedCertificate, String>(
  (ref, credentialId) => ref.watch(verifyApiProvider).verify(credentialId),
  isAutoDispose: true,
);
