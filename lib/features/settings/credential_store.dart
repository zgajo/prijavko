// WHY: Credentials never touch Drift, SharedPreferences, or the cookie jar.
// They live only in flutter_secure_storage (Android Keystore). The
// `allowBackup=false` manifest declaration (Story 1.1 AC4) prevents them
// leaving the device. `CredentialStore` is the single entry point — no
// feature may read credentials from any other surface.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prijavko/core/errors/app_error.dart';
import 'package:prijavko/core/result/result.dart';

// Key versioning (`_v1`) allows future key migration without data loss.
// When adding a v2 key, migrate from v1 to v2 on first read, then delete v1.
const _keyUsername = 'prijavko_cred_username_v1';
const _keyPassword = 'prijavko_cred_password_v1';
const _keyApiKey = 'prijavko_cred_apikey_v1';

final class Credentials {
  const Credentials({
    required this.username,
    required this.password,
    required this.apiKey,
  });

  final String username;
  final String password;
  final String apiKey;
}

class CredentialStore {
  // Default uses Keystore-backed custom ciphers (flutter_secure_storage v10+
  // default on Android — no need to set AndroidOptions explicitly).
  CredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<Result<void, StorageError>> saveCredentials({
    required String username,
    required String password,
    required String apiKey,
  }) async {
    try {
      // Writes are independent — partial state is tolerable; the next
      // `saveCredentials` call overwrites. No rollback on failure.
      await _storage.write(key: _keyUsername, value: username);
      await _storage.write(key: _keyPassword, value: password);
      await _storage.write(key: _keyApiKey, value: apiKey);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('Credential write failed', cause: e));
    }
  }

  Future<Result<Credentials, StorageError>> loadCredentials() async {
    try {
      final username = await _storage.read(key: _keyUsername);
      final password = await _storage.read(key: _keyPassword);
      final apiKey = await _storage.read(key: _keyApiKey);
      if (username == null || password == null || apiKey == null) {
        return const Err(StorageError('Credentials not found'));
      }
      return Ok(
        Credentials(username: username, password: password, apiKey: apiKey),
      );
    } catch (e) {
      return Err(StorageError('Credential read failed', cause: e));
    }
  }

  Future<Result<void, StorageError>> wipeCredentials() async {
    try {
      // Delete only the three keys owned by CredentialStore — never
      // `storage.deleteAll()` which would wipe unrelated plugin keys.
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyApiKey);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('Credential wipe failed', cause: e));
    }
  }
}
