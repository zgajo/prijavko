import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/features/auth/login_failure.dart';
import 'package:prijavko/features/auth/login_response_classifier.dart';

Response<dynamic> _response(int statusCode, Object? data) {
  return Response(
    requestOptions: RequestOptions(path: '/test'),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  group('classifyLoginResponse', () {
    test('200 + true → success (null)', () {
      final result = classifyLoginResponse(response: _response(200, true));
      expect(result, isNull);
    });

    test('200 + "true" string → success (null)', () {
      final result = classifyLoginResponse(response: _response(200, 'true'));
      expect(result, isNull);
    });

    test('200 + false → CredentialsInvalid(userMessage: null)', () {
      final result = classifyLoginResponse(response: _response(200, false));
      expect(result, isA<CredentialsInvalid>());
      expect((result! as CredentialsInvalid).userMessage, isNull);
    });

    test('200 + "false" string → CredentialsInvalid', () {
      final result = classifyLoginResponse(response: _response(200, 'false'));
      expect(result, isA<CredentialsInvalid>());
    });

    test(
      '200 + Map with invalid credentials SystemMessage → CredentialsInvalid with UserMessage',
      () {
        final result = classifyLoginResponse(
          response: _response(200, {
            'UserMessage': 'Foo',
            'SystemMessage': 'Invalid credentials',
          }),
        );
        expect(result, isA<CredentialsInvalid>());
        expect((result! as CredentialsInvalid).userMessage, 'Foo');
      },
    );

    test('200 + locked out SystemMessage → AccountLockedOut ~now+6min', () {
      final before = DateTime.now();
      final result = classifyLoginResponse(
        response: _response(200, {
          'UserMessage': 'Bar',
          'SystemMessage': 'User is locked out — wait 5 minutes',
        }),
      );
      final after = DateTime.now();

      expect(result, isA<AccountLockedOut>());
      final lockout = result! as AccountLockedOut;
      final expectedMin = before.add(const Duration(minutes: 6));
      final expectedMax = after.add(const Duration(minutes: 6, seconds: 1));
      expect(
        lockout.retryAfter.isAfter(
          expectedMin.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(lockout.retryAfter.isBefore(expectedMax), isTrue);
    });

    test('200 + apikey rejected SystemMessage → ContractBreak', () {
      final result = classifyLoginResponse(
        response: _response(200, {
          'UserMessage': null,
          'SystemMessage':
              'Application is not registered or is deactivated or API key has expired.',
        }),
      );
      expect(result, isA<ContractBreak>());
      expect((result! as ContractBreak).reason, 'apikey rejected');
    });

    test('400 + Map with invalid SystemMessage → CredentialsInvalid', () {
      final result = classifyLoginResponse(
        response: _response(400, {
          'UserMessage': 'X',
          'SystemMessage': 'Neispravni podaci',
        }),
      );
      expect(result, isA<CredentialsInvalid>());
      expect((result! as CredentialsInvalid).userMessage, 'X');
    });

    test('401 → CredentialsInvalid(userMessage: null)', () {
      final result = classifyLoginResponse(response: _response(401, null));
      expect(result, isA<CredentialsInvalid>());
      expect((result! as CredentialsInvalid).userMessage, isNull);
    });

    test('403 → CredentialsInvalid(userMessage: null)', () {
      final result = classifyLoginResponse(response: _response(403, null));
      expect(result, isA<CredentialsInvalid>());
    });

    test('500 → ServerError(500)', () {
      final result = classifyLoginResponse(response: _response(500, null));
      expect(result, isA<ServerError>());
      expect((result! as ServerError).statusCode, 500);
    });

    test('502 → ServerError(502)', () {
      final result = classifyLoginResponse(response: _response(502, null));
      expect(result, isA<ServerError>());
      expect((result! as ServerError).statusCode, 502);
    });

    test('200 + unexpected scalar (42) → ContractBreak', () {
      final result = classifyLoginResponse(response: _response(200, 42));
      expect(result, isA<ContractBreak>());
    });

    test('200 + null → ContractBreak', () {
      final result = classifyLoginResponse(response: _response(200, null));
      expect(result, isA<ContractBreak>());
    });

    test(
      '200 + empty Map (no SystemMessage) → CredentialsInvalid(userMessage: null)',
      () {
        final result = classifyLoginResponse(
          response: _response(200, <String, dynamic>{}),
        );
        expect(result, isA<CredentialsInvalid>());
        expect((result! as CredentialsInvalid).userMessage, isNull);
      },
    );

    // Croatian regex coverage
    test('SystemMessage "Korisnički račun zaključan" → AccountLockedOut', () {
      final result = classifyLoginResponse(
        response: _response(200, {
          'UserMessage': 'Locked',
          'SystemMessage': 'Korisnički račun zaključan',
        }),
      );
      expect(result, isA<AccountLockedOut>());
    });

    test('SystemMessage "Nevažeća lozinka" → CredentialsInvalid', () {
      final result = classifyLoginResponse(
        response: _response(200, {
          'UserMessage': 'Bad password',
          'SystemMessage': 'Nevažeća lozinka',
        }),
      );
      expect(result, isA<CredentialsInvalid>());
      expect((result! as CredentialsInvalid).userMessage, 'Bad password');
    });
  });
}
