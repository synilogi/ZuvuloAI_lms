import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/token_store.dart';

/// The session token, in the platform's secure store only (§15, §18): on Android, AES-GCM storage
/// whose key lives in the Keystore (flutter_secure_storage 11 removed the `EncryptedSharedPreferences`
/// backend the spec named and migrated to this cipher); on iOS, the Keychain unlocked on this device
/// only. The key carries the environment name, so a staging token is never sent to production.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({required String environment, FlutterSecureStorage? storage})
    : _key = 'session.token.$environment',
      _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
          );

  final String _key;
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final token = await _storage.read(key: _key);
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore(environment: ref.watch(appConfigProvider).flavor.name),
);
