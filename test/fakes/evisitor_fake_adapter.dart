// Story 1.7: fake eVisitor HTTP adapter with login routing.
//
// To swap in a real eVisitor apikey:
//   1. Obtain the key from HTZ (Hrvatska turistička zajednica) per the
//      registration flow in PRD §FR5.
//   2. Build with: flutter build appbundle \
//        --dart-define=EVISITOR_ENV=prod \
//        --dart-define=EVISITOR_API_KEY=<paste-key>
//   3. Verify by running an integration test against testApi:
//        flutter test --dart-define=EVISITOR_ENV=test \
//                     --dart-define=EVISITOR_API_KEY=<test-key> \
//                     integration_test/evisitor_login_canary_test.dart
//      (Canary test scaffold deferred to Story 1.1 testapi-canary workflow.)
//
// TODO(story-6.3): add ImportTourists routing.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

sealed class FakeLoginScript {
  const FakeLoginScript();
}

final class FakeLoginSuccess extends FakeLoginScript {
  const FakeLoginSuccess();
}

final class FakeLoginCredentialsInvalid extends FakeLoginScript {
  const FakeLoginCredentialsInvalid({
    this.userMessage = 'Korisničko ime ili lozinka nisu ispravni.',
  });
  final String userMessage;
}

final class FakeLoginLockedOut extends FakeLoginScript {
  const FakeLoginLockedOut();
}

/// 5xx server-error path. AC10.3 widget test asserts the Croatian
/// `loginServerError` copy is rendered when the adapter returns 500.
final class FakeLoginServerError extends FakeLoginScript {
  const FakeLoginServerError({this.statusCode = 500});
  final int statusCode;
}

final class FakeLoginContractBreak extends FakeLoginScript {
  const FakeLoginContractBreak({this.userMessage});
  final String? userMessage;
}

final class FakeLoginNetworkError extends FakeLoginScript {
  const FakeLoginNetworkError();
}

class EvisitorFakeAdapter implements HttpClientAdapter {
  EvisitorFakeAdapter({this.scriptedLogin = const FakeLoginSuccess()});

  final FakeLoginScript scriptedLogin;

  /// Captured for tests that assert outbound payload shape.
  RequestOptions? lastRequest;

  /// Optional delay for double-tap / spinner tests.
  Duration? responseDelay;

  int _requestCount = 0;
  int get requestCount => _requestCount;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _requestCount++;
    lastRequest = options;

    if (responseDelay != null) {
      await Future<void>.delayed(responseDelay!);
    }

    if (options.path.contains('/Authentication/Login')) {
      return _handleLogin(options);
    }

    // Non-login path: return existing 200/empty response.
    // TODO(story-6.3): add ImportTourists routing.
    return ResponseBody.fromString('', 200, headers: {});
  }

  ResponseBody _handleLogin(RequestOptions options) {
    final data = options.data as Map<String, Object?>?;

    // Poka-yoke: verify request body contains required fields.
    if (data == null ||
        !data.containsKey('userName') ||
        !data.containsKey('password') ||
        !data.containsKey('apikey') ||
        data['PersistCookie'] != true) {
      return ResponseBody.fromString(
        jsonEncode({
          'SystemMessage':
              'Missing required fields: userName, password, apikey, PersistCookie',
        }),
        400,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }

    return switch (scriptedLogin) {
      FakeLoginSuccess() => _successResponse(),
      FakeLoginCredentialsInvalid(:final userMessage) =>
        _credentialsInvalidResponse(userMessage),
      FakeLoginLockedOut() => _lockedOutResponse(),
      FakeLoginContractBreak(:final userMessage) => _contractBreakResponse(
        userMessage,
      ),
      FakeLoginServerError(:final statusCode) => _serverErrorResponse(
        statusCode,
      ),
      FakeLoginNetworkError() => throw DioException(
        type: DioExceptionType.connectionError,
        message: 'connection reset by peer',
        requestOptions: options,
      ),
    };
  }

  ResponseBody _serverErrorResponse(int statusCode) {
    return ResponseBody.fromString(
      '',
      statusCode,
      headers: {
        'content-type': ['text/plain'],
      },
    );
  }

  ResponseBody _successResponse() {
    // WHY: cookies are separately listed as multiple Set-Cookie headers
    // (not a single semicolon-joined string). dio_cookie_manager handles
    // parsing.
    return ResponseBody.fromString(
      'true',
      200,
      headers: {
        'content-type': ['application/json'],
        'set-cookie': [
          'authentication=fake-auth-cookie-value; Path=/; HttpOnly; Secure; Max-Age=1209600',
          'affinity=fake-affinity-cookie-value; Path=/; Secure',
          'language=hr; Path=/; Max-Age=31536000',
        ],
      },
    );
  }

  ResponseBody _credentialsInvalidResponse(String userMessage) {
    return ResponseBody.fromString(
      jsonEncode({
        'UserMessage': userMessage,
        'SystemMessage': 'Invalid credentials',
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  ResponseBody _lockedOutResponse() {
    return ResponseBody.fromString(
      jsonEncode({
        'UserMessage': 'Korisnički račun je zaključan na 5 minuta.',
        'SystemMessage': 'User is locked out',
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  ResponseBody _contractBreakResponse(String? userMessage) {
    return ResponseBody.fromString(
      jsonEncode({
        'UserMessage': userMessage,
        'SystemMessage':
            'Application is not registered or is deactivated or API key has expired.',
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
