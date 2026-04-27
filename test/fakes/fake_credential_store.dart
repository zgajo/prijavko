// WHY concrete inheritance (not interface): CredentialStore lacks an abstract
// interface — same pattern as CapturePreferenceStore (Story 1.6 deferred
// concern). If a second consumer needs an interface seam, revisit then
// (Story 1.9 re-entry).
//
// All methods are overridden, so the super's FlutterSecureStorage is never
// touched in practice.

import 'package:prijavko/core/errors/app_error.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/settings/credential_store.dart';

class FakeCredentialStore extends CredentialStore {
  Credentials? savedCredentials;
  bool shouldFail = false;

  @override
  Future<Result<void, StorageError>> saveCredentials({
    required String username,
    required String password,
    required String apiKey,
  }) async {
    if (shouldFail) {
      return const Err(StorageError('Fake save failed'));
    }
    savedCredentials = Credentials(
      username: username,
      password: password,
      apiKey: apiKey,
    );
    return const Ok(null);
  }

  @override
  Future<Result<Credentials, StorageError>> loadCredentials() async {
    if (savedCredentials == null) {
      return const Err(StorageError('Credentials not found'));
    }
    return Ok(savedCredentials!);
  }

  @override
  Future<Result<void, StorageError>> wipeCredentials() async {
    savedCredentials = null;
    return const Ok(null);
  }
}
