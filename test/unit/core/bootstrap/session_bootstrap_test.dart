import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap.dart';
import 'package:prijavko/core/bootstrap/session_bootstrap_provider.dart';
import 'package:prijavko/core/errors/app_error.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/facility/has_facility_profile.dart';
import 'package:prijavko/features/settings/credential_store.dart';

import '../../../fakes/fake_credential_store.dart';

class _ThrowingCredentialStore extends CredentialStore {
  @override
  Future<Result<Credentials, StorageError>> loadCredentials() async {
    throw const StorageError('Simulated Keystore failure');
  }
}

// Builds an isolated ProviderContainer with the given overrides so each test
// gets a fresh Riverpod scope. Automatically disposed after the test.
ProviderContainer _makeContainer({
  required CredentialStore credentialStore,
  required CookieJar jar,
  bool hasFacility = false,
}) {
  final container = ProviderContainer(
    // Riverpod 3 retries async provider failures by default. Bootstrap must
    // fail fast in tests so StorageError surfaces deterministically.
    retry: (retryCount, error) => null,
    overrides: [
      credentialStoreProvider.overrideWithValue(credentialStore),
      cookieJarProvider.overrideWithValue(jar),
      hasFacilityProfileProvider.overrideWith((_) async => hasFacility),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// Seeds a CookieJar with the given cookies for the eVisitor URL.
Future<CookieJar> _jarWith(List<Cookie> cookies) async {
  final jar = CookieJar();
  await jar.saveFromResponse(
    Uri.parse('https://www.evisitor.hr/Resources/'),
    cookies,
  );
  return jar;
}

Cookie _authCookie({String? path, DateTime? expires}) {
  final c = Cookie('authentication', 'fake-session-token')
    ..path = path ?? '/Resources/'
    ..secure = true
    ..httpOnly = true;
  if (expires != null) c.expires = expires;
  return c;
}

void main() {
  group('sessionBootstrap decision matrix', () {
    test('no credentials, no facility profile → BootFreshFirstRun', () async {
      final container = _makeContainer(
        credentialStore: FakeCredentialStore(), // no credentials seeded
        jar: CookieJar(),
      );
      final result = await container.read(sessionBootstrapProvider.future);
      expect(result, isA<BootFreshFirstRun>());
    });

    test(
      'no credentials, facility profile present → BootCredentialsMissing',
      () async {
        final container = _makeContainer(
          credentialStore: FakeCredentialStore(),
          jar: CookieJar(),
          hasFacility: true,
        );
        final result = await container.read(sessionBootstrapProvider.future);
        expect(result, isA<BootCredentialsMissing>());
      },
    );

    test(
      'credentials present, no authentication cookie → BootCookiesMissing',
      () async {
        final store = FakeCredentialStore()
          ..savedCredentials = const Credentials(
            username: 'user',
            password: 'pass',
            apiKey: 'key',
          );
        final container = _makeContainer(
          credentialStore: store,
          jar: CookieJar(), // empty jar
        );
        final result = await container.read(sessionBootstrapProvider.future);
        expect(result, isA<BootCookiesMissing>());
      },
    );

    test(
      'credentials present, only affinity and language cookies → BootCookiesMissing',
      () async {
        final store = FakeCredentialStore()
          ..savedCredentials = const Credentials(
            username: 'user',
            password: 'pass',
            apiKey: 'key',
          );
        // Verifies that 'affinity' and 'language' don't count as session cookies.
        final jar = await _jarWith([
          Cookie('ARRAffinity', 'affinity-value')
            ..path = '/Resources/'
            ..secure = true,
          Cookie('language', 'hr')
            ..path = '/Resources/'
            ..secure = true,
        ]);
        final container = _makeContainer(credentialStore: store, jar: jar);
        final result = await container.read(sessionBootstrapProvider.future);
        expect(result, isA<BootCookiesMissing>());
      },
    );

    test(
      'credentials present, authentication cookie present → BootSessionLive',
      () async {
        final store = FakeCredentialStore()
          ..savedCredentials = const Credentials(
            username: 'user',
            password: 'pass',
            apiKey: 'key',
          );
        final jar = await _jarWith([_authCookie()]);
        final container = _makeContainer(credentialStore: store, jar: jar);
        final result = await container.read(sessionBootstrapProvider.future);
        expect(result, isA<BootSessionLive>());
      },
    );

    test(
      'credentials present, authentication cookie in wrong path → BootCookiesMissing',
      () async {
        // Verifies the URL passed to loadForRequest matches eVisitor's cookie
        // scope. A cookie scoped to /foo/ would not be returned for /Resources/.
        final store = FakeCredentialStore()
          ..savedCredentials = const Credentials(
            username: 'user',
            password: 'pass',
            apiKey: 'key',
          );
        final jar = await _jarWith([_authCookie(path: '/foo/')]);
        final container = _makeContainer(credentialStore: store, jar: jar);
        final result = await container.read(sessionBootstrapProvider.future);
        expect(result, isA<BootCookiesMissing>());
      },
    );

    test(
      'credentials present, authentication cookie expired → BootCookiesMissing',
      () async {
        // Verifies the 14-day-elapsed branch: PersistCookieJar with
        // ignoreExpires=false prunes expired cookies on read, so loadForRequest
        // returns nothing → BootCookiesMissing.
        final store = FakeCredentialStore()
          ..savedCredentials = const Credentials(
            username: 'user',
            password: 'pass',
            apiKey: 'key',
          );
        final jar = CookieJar(); // plain CookieJar respects expiry on load
        await jar.saveFromResponse(
          Uri.parse('https://www.evisitor.hr/Resources/'),
          [
            _authCookie(
              expires: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
        );
        final container = _makeContainer(credentialStore: store, jar: jar);
        final result = await container.read(sessionBootstrapProvider.future);
        expect(result, isA<BootCookiesMissing>());
      },
    );

    test(
      'credentialStore load throws StorageError → propagates as Future error',
      () async {
        // Jidoka: confirms no BootError swallowing — bootstrap failure is a
        // startup crash, not a fifth UI state. Uses a store that throws (not
        // wraps in Err) to simulate an unexpected Keystore failure.
        final container = ProviderContainer(
          // Keep the error-path test deterministic under Riverpod 3 by
          // disabling automatic retries for this container.
          retry: (retryCount, error) => null,
          overrides: [
            credentialStoreProvider.overrideWith(
              (_) => _ThrowingCredentialStore(),
            ),
            cookieJarProvider.overrideWithValue(CookieJar()),
            hasFacilityProfileProvider.overrideWith((_) async => false),
          ],
        );
        addTearDown(container.dispose);
        await expectLater(
          container.read(sessionBootstrapProvider.future),
          throwsA(isA<StorageError>()),
        );
      },
    );
  });
}
