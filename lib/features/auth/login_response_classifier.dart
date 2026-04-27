// WHY a pure function: classifier accepts Response<dynamic> only; tests pass
// synthetic Response instances without spinning Dio. Pure-Dart unit tests, no
// widget tester.
//
// TODO(story-2.2): EvisitorErrorClassifier.classify subsumes this function —
// it classifies DioException in addition to Response, covering the full
// error surface. This function becomes a private helper inside that classifier.

import 'package:dio/dio.dart';
import 'package:prijavko/features/auth/login_failure.dart';

// SystemMessage regex patterns — case-insensitive, applied in order.
// Source: research §Croatian regex patterns + research §wiki failure example.
final _lockedPattern = RegExp(r'locked|zaključan', caseSensitive: false);
final _invalidPattern = RegExp(
  r'invalid|nevažeć|neispra|netoč',
  caseSensitive: false,
);
final _apiKeyPattern = RegExp(
  r'api key|not registered|not registered or is deactivated',
  caseSensitive: false,
);

/// Classifies a raw eVisitor login [response] into a [LoginFailure] or null.
///
/// Returns `null` on success (caller persists credentials, navigates).
/// Returns a [LoginFailure] variant on any failure (caller surfaces it).
///
/// Decision tree is exhaustive and ordered per AC4.2 — status code first,
/// then body shape, then SystemMessage regex matching.
///
/// [lockoutDuration] is the prijavko-side budget (default 6 minutes per
/// architecture §Circuit breaker). Tests inject a short value (e.g. 2 seconds)
/// to exercise the LoginIdle-after-expiry transition without a real wait.
LoginFailure? classifyLoginResponse({
  required Response<dynamic> response,
  Duration lockoutDuration = const Duration(minutes: 6),
}) {
  final status = response.statusCode ?? -1;
  final body = response.data;

  // 200 + body == true → success
  if (status == 200 && body == true) return null;
  // Dio may parse "true" as String when responseType is not JSON.
  if (status == 200 && body is String && body.trim().toLowerCase() == 'true') {
    return null;
  }

  // 200 + body == false → CredentialsInvalid (Rhetos boolean-false path)
  if (status == 200 && body == false) {
    return const CredentialsInvalid();
  }
  if (status == 200 && body is String && body.trim().toLowerCase() == 'false') {
    return const CredentialsInvalid();
  }

  // 200 or 400 + body is Map → inspect SystemMessage
  if ((status == 200 || status == 400) && body is Map) {
    return _classifyMapBody(body, lockoutDuration);
  }

  // 401 or 403 → CredentialsInvalid (standard rejection on Login endpoint)
  if (status == 401 || status == 403) {
    return const CredentialsInvalid();
  }

  // 5xx → ServerError
  if (status >= 500) return ServerError(status);

  // Anything else → ContractBreak
  return ContractBreak(
    'unexpected statusCode=$status body=${body.runtimeType}',
  );
}

LoginFailure _classifyMapBody(
  Map<dynamic, dynamic> body,
  Duration lockoutDuration,
) {
  // WHY defensive cast: a malformed server response with a non-String
  // SystemMessage/UserMessage (e.g. nested object, number) would throw a
  // TypeError outside the caller's try/catch and bypass the Result contract.
  // Treat non-String values as absent — fall through to the "no SystemMessage"
  // safe default per AC4.3 last row.
  final rawSystemMessage = body['SystemMessage'];
  final rawUserMessage = body['UserMessage'];
  final systemMessage = rawSystemMessage is String ? rawSystemMessage : null;
  final userMessage = rawUserMessage is String ? rawUserMessage : null;

  if (systemMessage == null || systemMessage.isEmpty) {
    // Empty Map or Map without SystemMessage — safe default per AC4.3 last row.
    return CredentialsInvalid(userMessage: userMessage);
  }

  // Ordered regex matching per AC4.3.
  if (_lockedPattern.hasMatch(systemMessage)) {
    return AccountLockedOut(retryAfter: DateTime.now().add(lockoutDuration));
  }

  if (_apiKeyPattern.hasMatch(systemMessage)) {
    return const ContractBreak('apikey rejected');
  }

  if (_invalidPattern.hasMatch(systemMessage)) {
    return CredentialsInvalid(userMessage: userMessage);
  }

  // None of the above — surface the Croatian explanation verbatim.
  return CredentialsInvalid(userMessage: userMessage);
}
