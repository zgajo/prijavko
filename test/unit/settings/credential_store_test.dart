// guards AC7.5
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/errors/app_error.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/settings/credential_store.dart';

// In-memory fake — pure Dart, no platform channels.
// Extends FlutterSecureStorage (const constructor) and overrides only the three
// methods CredentialStore uses; the rest are never called in these tests.
class _FakeFlutterSecureStorage extends FlutterSecureStorage {
  _FakeFlutterSecureStorage() : super();

  final Map<String, String> _map = {};

  Map<String, String> get internalMap => Map.unmodifiable(_map);

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _map[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _map.remove(key);
}

void main() {
  late _FakeFlutterSecureStorage fakeStorage;
  late CredentialStore store;

  setUp(() {
    fakeStorage = _FakeFlutterSecureStorage();
    store = CredentialStore(storage: fakeStorage);
  });

  group('CredentialStore', () {
    test('saveCredentials writes all three keys', () async {
      await store.saveCredentials(
        username: 'user1',
        password: 'pass1',
        apiKey: 'key1',
      );
      expect(fakeStorage.internalMap['prijavko_cred_username_v1'], 'user1');
      expect(fakeStorage.internalMap['prijavko_cred_password_v1'], 'pass1');
      expect(fakeStorage.internalMap['prijavko_cred_apikey_v1'], 'key1');
    });

    test(
      'loadCredentials returns Ok(Credentials) when all three keys exist',
      () async {
        await store.saveCredentials(username: 'u', password: 'p', apiKey: 'k');
        final result = await store.loadCredentials();
        expect(result, isA<Ok<Credentials, StorageError>>());
        final creds = (result as Ok<Credentials, StorageError>).value;
        expect(creds.username, 'u');
        expect(creds.password, 'p');
        expect(creds.apiKey, 'k');
      },
    );

    test('loadCredentials returns Err when no keys stored', () async {
      final result = await store.loadCredentials();
      expect(result, isA<Err<Credentials, StorageError>>());
      expect(
        (result as Err<Credentials, StorageError>).error.message,
        'Credentials not found',
      );
    });

    test(
      'loadCredentials returns Err when only some keys are present',
      () async {
        fakeStorage._map['prijavko_cred_username_v1'] = 'u';
        // password and apiKey missing
        final result = await store.loadCredentials();
        expect(result, isA<Err<Credentials, StorageError>>());
      },
    );

    test('wipeCredentials deletes all three owned keys', () async {
      await store.saveCredentials(username: 'u', password: 'p', apiKey: 'k');
      await store.wipeCredentials();
      // Directly inspect storage — not via loadCredentials — to catch partial-wipe bugs.
      expect(
        fakeStorage.internalMap.containsKey('prijavko_cred_username_v1'),
        isFalse,
      );
      expect(
        fakeStorage.internalMap.containsKey('prijavko_cred_password_v1'),
        isFalse,
      );
      expect(
        fakeStorage.internalMap.containsKey('prijavko_cred_apikey_v1'),
        isFalse,
      );
    });

    test(
      'wipeCredentials does NOT delete keys not owned by CredentialStore',
      () async {
        // Pre-seed an unrelated key
        fakeStorage._map['some_other_plugin_key'] = 'keep_me';
        await store.saveCredentials(username: 'u', password: 'p', apiKey: 'k');
        await store.wipeCredentials();
        expect(fakeStorage.internalMap['some_other_plugin_key'], 'keep_me');
      },
    );
  });
}
