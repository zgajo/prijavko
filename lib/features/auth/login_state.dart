// WHY no LoginSuccess variant: success drives a one-shot navigation
// (context.goNamed('home')), not a persistent UI state. The route tree
// owns the post-login screens.
//
// TODO(story-2.1): AuthState (keepAlive, app-scoped) subsumes LoginState.
// LoginNotifier becomes a thin adapter over AuthNotifier.login().

import 'package:prijavko/features/auth/login_failure.dart';

/// Interim login-screen state — 3 variants, autoDispose-scoped.
sealed class LoginState {
  const LoginState();
}

final class LoginIdle extends LoginState {
  const LoginIdle({this.error});

  /// Surfaces last failure inline; cleared when fields change.
  final LoginFailure? error;
}

final class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

final class LoginLockedOut extends LoginState {
  const LoginLockedOut({required this.retryAfter});
  final DateTime retryAfter;
}
