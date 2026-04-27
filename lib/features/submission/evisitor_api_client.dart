// Single entry point for all eVisitor HTTP per architecture §Architectural
// Boundaries — External API boundary table.
//
// Story 1.7 ships only login(). Future methods:
// TODO(story-6.3): importTourists() — XML-as-string-in-JSON submission.
// TODO(story-2.6): hello() — opportunistic auth check on foreground.

import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/core/env/evisitor_api_key.dart';
import 'package:prijavko/core/env/evisitor_env.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/auth/login_failure.dart';
import 'package:prijavko/features/auth/login_response_classifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'evisitor_api_client.g.dart';

class EvisitorApiClient {
  EvisitorApiClient(this._dio);
  final Dio _dio;

  /// Override in tests to simulate missing apikey in non-fake env.
  @visibleForTesting
  bool Function() isApiKeyAvailable = () =>
      evisitorEnv == EvisitorEnv.fake || evisitorApiKey.isNotEmpty;

  /// POST /Resources/AspNetFormsAuth/Authentication/Login
  ///
  /// Body: {userName, password, apikey, PersistCookie: true}
  /// Success: 200 + body == true + Set-Cookie for authentication/affinity/language
  /// Failure: 200 + {UserMessage, SystemMessage} | 200 + body == false | 400 | 401 | 403 | 5xx | network
  Future<Result<void, LoginFailure>> login({
    required String userName,
    required String password,
  }) async {
    // API-key sanity check at the call site, not in the const (AC2.4).
    if (!isApiKeyAvailable()) {
      return const Err(
        ContractBreak('EVISITOR_API_KEY missing for non-fake build'),
      );
    }

    try {
      final response = await _dio.post<dynamic>(
        'Resources/AspNetFormsAuth/Authentication/Login',
        data: <String, Object?>{
          'userName': userName,
          'password': password,
          'apikey': evisitorApiKey,
          'PersistCookie': true,
        },
      );

      final failure = classifyLoginResponse(response: response);
      if (failure != null) return Err(failure);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_classifyDioException(e));
    }
  }
}

LoginFailure _classifyDioException(DioException e) {
  // Connection-level failures → NetworkUnreachable.
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const NetworkUnreachable();
  }

  // SocketException wrapped in DioException → NetworkUnreachable.
  if (e.error is SocketException) {
    return const NetworkUnreachable();
  }

  // Server responded but Dio threw (e.g. badResponse on non-2xx).
  if (e.response != null) {
    final failure = classifyLoginResponse(response: e.response!);
    if (failure != null) return failure;
  }

  return ContractBreak('DioException: ${e.type.name} ${e.message}');
}

// WHY keepAlive: same lifetime rationale as dioProvider — single Dio instance,
// single API client, shared across the entire app process.
@Riverpod(keepAlive: true)
EvisitorApiClient evisitorApiClient(Ref ref) {
  return EvisitorApiClient(ref.watch(dioProvider));
}
