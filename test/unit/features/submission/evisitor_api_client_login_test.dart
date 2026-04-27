import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/auth/login_failure.dart';
import 'package:prijavko/features/submission/evisitor_api_client.dart';

import '../../../fakes/evisitor_fake_adapter.dart';

EvisitorApiClient _buildClient(EvisitorFakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'))
    ..httpClientAdapter = adapter;
  // isApiKeyAvailable: tests run without --dart-define=EVISITOR_API_KEY.
  return EvisitorApiClient(dio, isApiKeyAvailable: () => true);
}

({EvisitorApiClient client, CookieJar jar}) _buildClientWithJar(
  EvisitorFakeAdapter adapter,
) {
  final jar = CookieJar();
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'))
    ..httpClientAdapter = adapter
    ..interceptors.add(CookieManager(jar));
  return (
    client: EvisitorApiClient(dio, isApiKeyAvailable: () => true),
    jar: jar,
  );
}

void main() {
  group('EvisitorApiClient.login', () {
    test('success path returns Ok', () async {
      final adapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      final client = _buildClient(adapter);

      final result = await client.login(userName: 'foo', password: 'bar');

      expect(result, isA<Ok<void, LoginFailure>>());
    });

    test('success path posts expected body', () async {
      final adapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      final client = _buildClient(adapter);

      await client.login(userName: 'testUser', password: 'testPass');

      final data = adapter.lastRequest?.data as Map<String, Object?>;
      expect(data['userName'], 'testUser');
      expect(data['password'], 'testPass');
      expect(data['apikey'], isA<String>());
      expect(data['PersistCookie'], true);
    });

    test(
      'credentials-invalid returns Err(CredentialsInvalid) with userMessage',
      () async {
        final adapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(userMessage: 'Foo'),
        );
        final client = _buildClient(adapter);

        final result = await client.login(userName: 'u', password: 'p');

        expect(result, isA<Err<void, LoginFailure>>());
        final failure = (result as Err).error;
        expect(failure, isA<CredentialsInvalid>());
        expect((failure as CredentialsInvalid).userMessage, 'Foo');
      },
    );

    test(
      'credentials-invalid with no userMessage returns CredentialsInvalid',
      () async {
        // The FakeLoginCredentialsInvalid returns a map with SystemMessage: "Invalid credentials"
        // which matches the _invalidPattern. userMessage is also provided.
        final adapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginCredentialsInvalid(userMessage: ''),
        );
        final client = _buildClient(adapter);

        final result = await client.login(userName: 'u', password: 'p');

        expect(result, isA<Err<void, LoginFailure>>());
        final failure = (result as Err).error;
        expect(failure, isA<CredentialsInvalid>());
      },
    );

    test(
      'locked-out returns Err(AccountLockedOut) with retryAfter ~6min',
      () async {
        final adapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginLockedOut(),
        );
        final client = _buildClient(adapter);
        final before = DateTime.now();

        final result = await client.login(userName: 'u', password: 'p');

        expect(result, isA<Err<void, LoginFailure>>());
        final failure = (result as Err).error as AccountLockedOut;
        expect(
          failure.retryAfter.isAfter(
            before.add(const Duration(minutes: 5, seconds: 59)),
          ),
          isTrue,
        );
      },
    );

    test('contract-break returns Err(ContractBreak)', () async {
      final adapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginContractBreak(),
      );
      final client = _buildClient(adapter);

      final result = await client.login(userName: 'u', password: 'p');

      expect(result, isA<Err<void, LoginFailure>>());
      final failure = (result as Err).error;
      expect(failure, isA<ContractBreak>());
    });

    test('network error returns Err(NetworkUnreachable)', () async {
      final adapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginNetworkError(),
      );
      final client = _buildClient(adapter);

      final result = await client.login(userName: 'u', password: 'p');

      expect(result, isA<Err<void, LoginFailure>>());
      final failure = (result as Err).error;
      expect(failure, isA<NetworkUnreachable>());
    });

    test(
      'missing apikey in non-fake env returns Err(ContractBreak) without HTTP call',
      () async {
        final adapter = EvisitorFakeAdapter(
          scriptedLogin: const FakeLoginSuccess(),
        );
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'))
          ..httpClientAdapter = adapter;
        // Simulate non-fake env with empty apikey.
        final client = EvisitorApiClient(dio, isApiKeyAvailable: () => false);

        final result = await client.login(userName: 'u', password: 'p');

        expect(result, isA<Err<void, LoginFailure>>());
        final failure = (result as Err).error;
        expect(failure, isA<ContractBreak>());
        // Verify no HTTP call was made.
        expect(adapter.lastRequest, isNull);
      },
    );

    test('success path persists all three cookies in the jar', () async {
      // AC10.2: assert all three cookies (authentication, affinity, language)
      // land in the CookieJar after a successful login. Validates that
      // CookieManager interceptor and Set-Cookie framing are wired correctly.
      final adapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginSuccess(),
      );
      final (:client, :jar) = _buildClientWithJar(adapter);

      final result = await client.login(userName: 'u', password: 'p');

      expect(result, isA<Ok<void, LoginFailure>>());
      final cookies = await jar.loadForRequest(
        Uri.parse('http://localhost/Resources/'),
      );
      final names = cookies.map((c) => c.name).toSet();
      expect(names, containsAll(['authentication', 'affinity', 'language']));
    });

    test('credentials-invalid path leaves cookie jar empty', () async {
      // AC10.2: failure paths must not emit Set-Cookie headers — the jar
      // remains empty so a stale auth cookie can't paper over a real failure.
      final adapter = EvisitorFakeAdapter(
        scriptedLogin: const FakeLoginCredentialsInvalid(),
      );
      final (:client, :jar) = _buildClientWithJar(adapter);

      final result = await client.login(userName: 'u', password: 'wrong');

      expect(result, isA<Err<void, LoginFailure>>());
      final cookies = await jar.loadForRequest(
        Uri.parse('http://localhost/Resources/'),
      );
      expect(cookies, isEmpty);
    });
  });
}
