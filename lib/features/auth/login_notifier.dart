// TODO(story-2.1): LoginNotifier becomes a thin adapter over
// AuthNotifier.login(). The screen's submit button calls
// authNotifier.login(creds) instead of loginNotifier.submit().
//
// TODO(story-2.5): The per-screen 6-minute lockout timer is replaced by
// AuthNotifier's circuit breaker (3 failures / 6-minute open).

import 'dart:async';

import 'package:prijavko/core/env/evisitor_api_key.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/features/auth/login_failure.dart';
import 'package:prijavko/features/auth/login_state.dart';
import 'package:prijavko/features/settings/credential_store.dart';
import 'package:prijavko/features/submission/evisitor_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_notifier.g.dart';

// WHY autoDispose (default): the form is a per-screen concern — failed
// attempts must not leak across navigation. Leaving the screen clears the
// form, the in-flight flag, and any error state. Returning starts fresh.
@riverpod
class LoginNotifier extends _$LoginNotifier {
  Timer? _lockoutTimer;
  // WHY a manual disposed flag (not Ref.mounted): flutter_riverpod 2.6 does
  // not expose `mounted` on the Notifier's Ref. The flag guards async paths
  // (login() future, lockout timer tick) from assigning to a disposed state.
  bool _disposed = false;

  @override
  LoginState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancelTimer();
    });
    return const LoginIdle();
  }

  /// Returns Ok on success (caller navigates), Err on failure (state updated).
  Future<Result<void, LoginFailure>> submit({
    required String username,
    required String password,
  }) async {
    // Poka-yoke against double-submit race (Story 1.6 retro finding).
    if (state is LoginSubmitting || state is LoginLockedOut) {
      return const Err(ContractBreak('submit called while busy or locked'));
    }

    state = const LoginSubmitting();

    final apiClient = ref.read(evisitorApiClientProvider);
    final result = await apiClient.login(
      userName: username,
      password: password,
    );

    return switch (result) {
      Ok() => _handleSuccess(username, password),
      Err(:final error) => _handleFailure(error),
    };
  }

  /// Clears any inline error so the form returns to a pristine `LoginIdle`.
  /// WHY: AC5.1 mandates `LoginIdle.error` is "cleared when fields change" —
  /// invoked by the screen on each keystroke when an error is currently shown.
  void clearError() {
    if (_disposed) return;
    final current = state;
    if (current is LoginIdle && current.error != null) {
      state = const LoginIdle();
    }
  }

  Future<Result<void, LoginFailure>> _handleSuccess(
    String username,
    String password,
  ) async {
    // WHY also save apikey: CredentialStore's contract was set in Story 1.3
    // with apiKey as a required field. The apikey value is the same compile-time
    // const — saving it preserves the existing API.
    final credStore = ref.read(credentialStoreProvider);
    final saveResult = await credStore.saveCredentials(
      username: username,
      password: password,
      apiKey: evisitorApiKey,
    );

    return switch (saveResult) {
      Ok() => const Ok(null),
      Err(:final error) => () {
        // WHY also flip state on save failure: without this the screen sees
        // `Err` from `submit()` but `state` remains `LoginSubmitting` — the
        // spinner never resolves and the form is unrecoverable. Surface the
        // failure so the user can retry (the Croatian forced-update copy is
        // accurate here: a Keystore write failure indicates a corrupted build
        // or platform-channel mismatch, neither of which is user-recoverable).
        final failure = ContractBreak(
          'credential save failed: ${error.message}',
        );
        if (!_disposed) state = LoginIdle(error: failure);
        return Err<void, LoginFailure>(failure);
      }(),
    };
  }

  Result<void, LoginFailure> _handleFailure(LoginFailure failure) {
    if (_disposed) return Err(failure);
    switch (failure) {
      case AccountLockedOut(:final retryAfter):
        _startLockoutTimer(retryAfter);
        state = LoginLockedOut(retryAfter: retryAfter);
      case _:
        state = LoginIdle(error: failure);
    }
    return Err(failure);
  }

  void _startLockoutTimer(DateTime retryAfter) {
    _cancelTimer();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) {
        _cancelTimer();
        return;
      }
      if (DateTime.now().isAfter(retryAfter)) {
        _cancelTimer();
        state = const LoginIdle();
      } else {
        // Re-emit the same variant so the UI rebuilds the countdown.
        state = LoginLockedOut(retryAfter: retryAfter);
      }
    });
  }

  void _cancelTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
  }
}
